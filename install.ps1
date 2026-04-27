# SpartaNode Desktop — Windows installer (PowerShell)
#
# Usage:
#   irm https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.ps1 | iex
#
# Options (when running as a saved script):
#   .\install.ps1 -Version "desktop-v0.1.0"
#   .\install.ps1 -FromFile "C:\Downloads\SpartaNode-0.1.0-win-x64.zip"
#   .\install.ps1 -NoGpg
#
param(
  [string]$Version = "",
  [string]$FromFile = "",
  [string]$SumsFile = "",
  [switch]$NoGpg,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

# ─── Configuration ────────────────────────────────────────────────────────────
$Repo = "spartaquant/spartanode-releases"
$GpgKeyUrl = "https://raw.githubusercontent.com/$Repo/main/keys/spartanode-releases.asc"
$GpgFingerprint = "0A6FC8B72DA11BDD3F5D99AB0A1ED33AF3EF9198"
$AppName = "SpartaNode"

if ($Help) {
  Write-Host "Usage: install.ps1 [-Version <tag>] [-FromFile <path>] [-SumsFile <path>] [-NoGpg]"
  exit 0
}

# ─── Helpers ──────────────────────────────────────────────────────────────────
function Info($msg)  { Write-Host "  [+] $msg" }
function Warn($msg)  { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "  [x] $msg" -ForegroundColor Red; exit 1 }

function Download($url, $dest) {
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
  } catch {
    Fail "Download failed: $url — $_"
  }
}

# ─── Resolve version ─────────────────────────────────────────────────────────
if (-not $Version) {
  Info "Resolving latest version..."
  try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
    $Version = $release.tag_name
  } catch {
    Fail "Could not resolve latest version. Check your internet connection."
  }
}

Info "Version: $Version"

# Strip leading "desktop-v" or "v" prefix for the filename
$FileVersion = $Version -replace '^desktop-v', '' -replace '^v', ''

# ─── Determine artifact filename ─────────────────────────────────────────────
$Artifact = "$AppName-$FileVersion-win-x64.zip"
$ReleaseUrl = "https://github.com/$Repo/releases/download/$Version"

# ─── Set up temp directory ────────────────────────────────────────────────────
$TmpDir = Join-Path $env:TEMP "spartanode-install-$(Get-Random)"
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

try {
  # ─── Download or copy artifacts ──────────────────────────────────────────
  if ($FromFile) {
    Info "Using local archive: $FromFile"
    if (-not (Test-Path $FromFile)) { Fail "File not found: $FromFile" }
    Copy-Item $FromFile (Join-Path $TmpDir $Artifact)
    if ($SumsFile) {
      if (-not (Test-Path $SumsFile)) { Fail "Sums file not found: $SumsFile" }
      Copy-Item $SumsFile (Join-Path $TmpDir "SHA256SUMS.txt")
      $ascFile = "$SumsFile.asc"
      if (Test-Path $ascFile) {
        Copy-Item $ascFile (Join-Path $TmpDir "SHA256SUMS.txt.asc")
      }
    }
  } else {
    Info "Downloading SHA256SUMS..."
    Download "$ReleaseUrl/SHA256SUMS.txt" (Join-Path $TmpDir "SHA256SUMS.txt")
    try {
      Download "$ReleaseUrl/SHA256SUMS.txt.asc" (Join-Path $TmpDir "SHA256SUMS.txt.asc")
    } catch { }

    Info "Downloading $Artifact..."
    Download "$ReleaseUrl/$Artifact" (Join-Path $TmpDir $Artifact)
  }

  # ─── GPG verification ────────────────────────────────────────────────────
  $gpgExe = $null
  if (-not $NoGpg) {
    # Try to find gpg: Git for Windows ships one
    $gpgCandidates = @(
      (Get-Command gpg -ErrorAction SilentlyContinue).Source,
      "$env:ProgramFiles\Git\usr\bin\gpg.exe",
      "${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe",
      "$env:ProgramFiles\GnuPG\bin\gpg.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($gpgCandidates) {
      $gpgExe = $gpgCandidates[0]
    }
  }

  $ascPath = Join-Path $TmpDir "SHA256SUMS.txt.asc"
  if ($NoGpg) {
    Warn "Skipping GPG verification (-NoGpg). Not recommended."
  } elseif ((Test-Path $ascPath) -and $gpgExe) {
    Info "Verifying GPG signature..."
    $gpgHome = Join-Path $TmpDir "gnupg"
    New-Item -ItemType Directory -Path $gpgHome -Force | Out-Null

    $keyPath = Join-Path $TmpDir "key.asc"
    Download $GpgKeyUrl $keyPath

    & $gpgExe --homedir $gpgHome --batch --import $keyPath 2>&1 | Out-Null

    $verifyResult = & $gpgExe --homedir $gpgHome --batch --verify `
      (Join-Path $TmpDir "SHA256SUMS.txt.asc") `
      (Join-Path $TmpDir "SHA256SUMS.txt") 2>&1

    if ($LASTEXITCODE -ne 0) {
      Fail "GPG signature verification FAILED. The release may have been tampered with."
    }
    Info "GPG signature verified."
  } elseif (-not (Test-Path $ascPath)) {
    Warn "No GPG signature found for this release."
  } else {
    Warn "gpg not found — skipping signature verification. Install Git for Windows or GnuPG for full verification."
  }

  # ─── SHA256 verification ─────────────────────────────────────────────────
  Info "Verifying SHA256 checksum..."
  $sumsContent = Get-Content (Join-Path $TmpDir "SHA256SUMS.txt") -Raw
  $expectedLine = ($sumsContent -split "`n") | Where-Object { $_ -match [regex]::Escape($Artifact) } | Select-Object -First 1
  if (-not $expectedLine) { Fail "Artifact not found in SHA256SUMS.txt" }

  $expectedHash = ($expectedLine -split '\s+')[0].Trim().ToLower()
  $actualHash = (Get-FileHash (Join-Path $TmpDir $Artifact) -Algorithm SHA256).Hash.ToLower()

  if ($expectedHash -ne $actualHash) {
    Fail "SHA256 checksum FAILED. Expected: $expectedHash, got: $actualHash"
  }
  Info "Checksum verified."

  # ─── Install ─────────────────────────────────────────────────────────────
  $InstallDir = Join-Path $env:LOCALAPPDATA "SpartaNode"

  # Back up existing install
  if (Test-Path $InstallDir) {
    $bakDir = "$InstallDir.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Info "Backing up existing installation to $bakDir..."
    Rename-Item $InstallDir $bakDir
  }

  Info "Extracting to $InstallDir..."
  Expand-Archive -Path (Join-Path $TmpDir $Artifact) -DestinationPath $InstallDir -Force

  # If the zip contains a single top-level folder, flatten it
  $children = Get-ChildItem $InstallDir
  if ($children.Count -eq 1 -and $children[0].PSIsContainer) {
    $inner = $children[0].FullName
    Get-ChildItem $inner | Move-Item -Destination $InstallDir
    Remove-Item $inner
  }

  # Remove Mark of the Web from all extracted files (prevents SmartScreen per-launch warning)
  Get-ChildItem -Path $InstallDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

  # ─── Create shortcuts ───────────────────────────────────────────────────
  $exePath = Join-Path $InstallDir "SpartaNode.exe"
  if (-not (Test-Path $exePath)) {
    # Try alternate name
    $exePath = Get-ChildItem $InstallDir -Filter "*.exe" | Select-Object -First 1 -ExpandProperty FullName
  }

  $iconPath = Join-Path $InstallDir "resources\icon.ico"
  if (-not (Test-Path $iconPath)) { $iconPath = $exePath }

  $ws = New-Object -ComObject WScript.Shell

  # Desktop shortcut
  $desktopLink = Join-Path ([Environment]::GetFolderPath("Desktop")) "SpartaNode.lnk"
  $sc = $ws.CreateShortcut($desktopLink)
  $sc.TargetPath = $exePath
  $sc.IconLocation = $iconPath
  $sc.WorkingDirectory = $InstallDir
  $sc.Description = "SpartaNode Desktop"
  $sc.Save()

  # Start Menu shortcut
  $startMenuDir = Join-Path ([Environment]::GetFolderPath("Programs")) "SpartaNode"
  New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
  $startLink = Join-Path $startMenuDir "SpartaNode.lnk"
  $sc = $ws.CreateShortcut($startLink)
  $sc.TargetPath = $exePath
  $sc.IconLocation = $iconPath
  $sc.WorkingDirectory = $InstallDir
  $sc.Description = "SpartaNode Desktop"
  $sc.Save()

  Write-Host ""
  Info "SpartaNode $FileVersion installed to $InstallDir"
  Info "Double-click the SpartaNode icon on your desktop to launch."
  if (-not (Test-Path variable:env:WIN_CSC_LINK)) {
    Warn "First launch: Windows may show 'Unknown publisher' — click 'More info > Run anyway'."
  }

} finally {
  # Clean up temp directory
  Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
