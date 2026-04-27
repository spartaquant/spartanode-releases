# SpartaNode Desktop — Windows uninstaller (PowerShell)
#
# Usage:
#   irm https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.ps1 | iex
#
# Options (when running as a saved script):
#   .\uninstall.ps1 -Purge
#
param(
  [switch]$Purge,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
  Write-Host "Usage: uninstall.ps1 [-Purge]"
  exit 0
}

function Info($msg)  { Write-Host "  [+] $msg" }
function Warn($msg)  { Write-Host "  [!] $msg" -ForegroundColor Yellow }

$InstallDir = Join-Path $env:LOCALAPPDATA "SpartaNode"
$DataDir = Join-Path $env:APPDATA "spartanode-desktop"
$DesktopLink = Join-Path ([Environment]::GetFolderPath("Desktop")) "SpartaNode.lnk"
$StartMenuDir = Join-Path ([Environment]::GetFolderPath("Programs")) "SpartaNode"

# Remove installation
if (Test-Path $InstallDir) {
  Info "Removing $InstallDir..."
  Remove-Item -Path $InstallDir -Recurse -Force
} else {
  Warn "Installation not found at $InstallDir"
}

# Remove any .bak directories
Get-ChildItem -Path $env:LOCALAPPDATA -Filter "SpartaNode.bak.*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  Info "Removing backup $($_.Name)..."
  Remove-Item $_.FullName -Recurse -Force
}

# Remove shortcuts
if (Test-Path $DesktopLink) {
  Info "Removing desktop shortcut..."
  Remove-Item $DesktopLink -Force
}
if (Test-Path $StartMenuDir) {
  Info "Removing Start Menu entry..."
  Remove-Item $StartMenuDir -Recurse -Force
}

# Purge user data
if ($Purge) {
  if (Test-Path $DataDir) {
    Info "Purging user data at $DataDir..."
    Remove-Item -Path $DataDir -Recurse -Force
  }
}

Write-Host ""
Info "SpartaNode has been uninstalled."
if (-not $Purge) {
  Info "User data preserved at $DataDir (use -Purge to remove)."
}
