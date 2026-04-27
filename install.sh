#!/usr/bin/env bash
# SpartaNode Desktop — Linux / macOS installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.sh | bash
#
# Options:
#   --version=X.Y.Z       Install a specific version (default: latest)
#   --from-file=PATH      Use a pre-downloaded archive (air-gap mode)
#   --sums-file=PATH      Use a pre-downloaded SHA256SUMS.txt (with --from-file)
#   --no-gpg              Skip GPG signature verification (not recommended)
#
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
REPO="spartaquant/spartanode-releases"
GPG_KEY_URL="https://raw.githubusercontent.com/${REPO}/main/keys/spartanode-releases.asc"
# Replace with actual fingerprint once the GPG key is generated
GPG_FINGERPRINT="REPLACE_WITH_ACTUAL_FINGERPRINT"
APP_NAME="SpartaNode"

# ─── Parse arguments ─────────────────────────────────────────────────────────
VERSION=""
FROM_FILE=""
SUMS_FILE=""
SKIP_GPG=false

for arg in "$@"; do
  case "$arg" in
    --version=*)  VERSION="${arg#--version=}" ;;
    --from-file=*) FROM_FILE="${arg#--from-file=}" ;;
    --sums-file=*) SUMS_FILE="${arg#--sums-file=}" ;;
    --no-gpg)     SKIP_GPG=true ;;
    --help|-h)
      echo "Usage: install.sh [--version=X.Y.Z] [--from-file=PATH] [--sums-file=PATH] [--no-gpg]"
      exit 0
      ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()  { echo "  [+] $*"; }
warn()  { echo "  [!] $*" >&2; }
fail()  { echo "  [x] $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

download() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    fail "Neither curl nor wget found. Install one and retry."
  fi
}

# ─── Detect platform ─────────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  PLATFORM="linux" ;;
  Darwin) PLATFORM="mac" ;;
  *)      fail "Unsupported OS: $OS. Use install.ps1 for Windows." ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH_LABEL="x64" ;;
  aarch64|arm64) ARCH_LABEL="arm64" ;;
  *)            fail "Unsupported architecture: $ARCH" ;;
esac

info "Detected platform: ${PLATFORM}-${ARCH_LABEL}"

# ─── Resolve version ─────────────────────────────────────────────────────────
if [ -z "$VERSION" ]; then
  info "Resolving latest version..."
  need_cmd curl
  VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')
  [ -n "$VERSION" ] || fail "Could not resolve latest version. Check your internet connection."
fi

info "Version: $VERSION"

# Strip leading "desktop-v" or "v" prefix for the filename
FILE_VERSION="${VERSION#desktop-v}"
FILE_VERSION="${FILE_VERSION#v}"

# ─── Determine artifact filename ─────────────────────────────────────────────
case "$PLATFORM" in
  linux) ARTIFACT="${APP_NAME}-${FILE_VERSION}-linux-${ARCH_LABEL}.tar.gz" ;;
  mac)   ARTIFACT="${APP_NAME}-${FILE_VERSION}-mac-${ARCH_LABEL}.zip" ;;
esac

RELEASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

# ─── Set up temp directory ────────────────────────────────────────────────────
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ─── Download or copy artifacts ──────────────────────────────────────────────
if [ -n "$FROM_FILE" ]; then
  info "Using local archive: $FROM_FILE"
  [ -f "$FROM_FILE" ] || fail "File not found: $FROM_FILE"
  cp "$FROM_FILE" "$TMP_DIR/$ARTIFACT"
  if [ -n "$SUMS_FILE" ]; then
    [ -f "$SUMS_FILE" ] || fail "Sums file not found: $SUMS_FILE"
    cp "$SUMS_FILE" "$TMP_DIR/SHA256SUMS.txt"
    # Look for .asc next to the sums file
    if [ -f "${SUMS_FILE}.asc" ]; then
      cp "${SUMS_FILE}.asc" "$TMP_DIR/SHA256SUMS.txt.asc"
    fi
  fi
else
  info "Downloading SHA256SUMS..."
  download "${RELEASE_URL}/SHA256SUMS.txt" "$TMP_DIR/SHA256SUMS.txt"
  download "${RELEASE_URL}/SHA256SUMS.txt.asc" "$TMP_DIR/SHA256SUMS.txt.asc" 2>/dev/null || true

  info "Downloading $ARTIFACT..."
  download "${RELEASE_URL}/${ARTIFACT}" "$TMP_DIR/${ARTIFACT}"
fi

# ─── GPG verification ────────────────────────────────────────────────────────
if [ "$SKIP_GPG" = true ]; then
  warn "Skipping GPG verification (--no-gpg). Not recommended."
elif [ -f "$TMP_DIR/SHA256SUMS.txt.asc" ]; then
  if command -v gpg >/dev/null 2>&1; then
    info "Importing GPG public key..."
    GPG_HOME="$TMP_DIR/gnupg"
    mkdir -p "$GPG_HOME"
    chmod 700 "$GPG_HOME"
    download "$GPG_KEY_URL" "$TMP_DIR/key.asc"

    # Verify the key fingerprint matches what we expect
    IMPORTED_FP=$(gpg --homedir "$GPG_HOME" --batch --import "$TMP_DIR/key.asc" 2>&1 \
      | grep -oE '[A-F0-9]{40}' | head -1 || true)

    if [ "$GPG_FINGERPRINT" != "REPLACE_WITH_ACTUAL_FINGERPRINT" ] && \
       [ -n "$IMPORTED_FP" ] && \
       [ "$IMPORTED_FP" != "$GPG_FINGERPRINT" ]; then
      fail "GPG key fingerprint mismatch! Expected: $GPG_FINGERPRINT, got: $IMPORTED_FP"
    fi

    info "Verifying GPG signature..."
    if ! gpg --homedir "$GPG_HOME" --batch --verify \
         "$TMP_DIR/SHA256SUMS.txt.asc" "$TMP_DIR/SHA256SUMS.txt" 2>/dev/null; then
      fail "GPG signature verification FAILED. The release may have been tampered with."
    fi
    info "GPG signature verified."
  else
    warn "gpg not found — skipping signature verification. Install gnupg for full verification."
  fi
else
  warn "No GPG signature found for this release — skipping signature verification."
fi

# ─── SHA256 verification ─────────────────────────────────────────────────────
info "Verifying SHA256 checksum..."
cd "$TMP_DIR"

if command -v sha256sum >/dev/null 2>&1; then
  # Filter to just our artifact line
  grep "$ARTIFACT" SHA256SUMS.txt | sha256sum -c - || fail "SHA256 checksum FAILED."
elif command -v shasum >/dev/null 2>&1; then
  # macOS
  EXPECTED=$(grep "$ARTIFACT" SHA256SUMS.txt | awk '{print $1}')
  ACTUAL=$(shasum -a 256 "$ARTIFACT" | awk '{print $1}')
  [ "$EXPECTED" = "$ACTUAL" ] || fail "SHA256 checksum FAILED. Expected: $EXPECTED, got: $ACTUAL"
else
  fail "Neither sha256sum nor shasum found."
fi

info "Checksum verified."

# ─── Install ─────────────────────────────────────────────────────────────────
case "$PLATFORM" in
  linux)
    INSTALL_DIR="$HOME/.local/share/SpartaNode"
    BIN_NAME="spartanode"

    # Back up existing install
    if [ -d "$INSTALL_DIR" ]; then
      info "Backing up existing installation..."
      mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)"
    fi

    info "Extracting to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    tar -xzf "$TMP_DIR/$ARTIFACT" -C "$INSTALL_DIR" --strip-components=1

    # Find the main executable
    EXECUTABLE=""
    for candidate in "$INSTALL_DIR/$BIN_NAME" "$INSTALL_DIR/SpartaNode" "$INSTALL_DIR/spartanode-desktop"; do
      if [ -f "$candidate" ]; then
        EXECUTABLE="$candidate"
        chmod +x "$EXECUTABLE"
        break
      fi
    done

    if [ -z "$EXECUTABLE" ]; then
      # Fallback: find any executable
      EXECUTABLE=$(find "$INSTALL_DIR" -maxdepth 1 -type f -executable | head -1 || true)
    fi

    # Write .desktop file
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    ICON_PATH="$INSTALL_DIR/resources/icon.png"
    [ -f "$ICON_PATH" ] || ICON_PATH=""

    cat > "$DESKTOP_DIR/spartanode.desktop" <<DESKTOP
[Desktop Entry]
Name=SpartaNode
Comment=Multi-user GUI orchestrator for Claude Code tasks
Exec=${EXECUTABLE:-$INSTALL_DIR/spartanode}
Icon=${ICON_PATH}
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=spartanode
DESKTOP

    # Update desktop database (best-effort)
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi

    echo ""
    info "SpartaNode $FILE_VERSION installed to $INSTALL_DIR"
    info "Launch from your application menu, or run:"
    info "  ${EXECUTABLE:-$INSTALL_DIR/spartanode}"
    ;;

  mac)
    INSTALL_DIR="$HOME/Applications"
    APP_BUNDLE="SpartaNode.app"

    mkdir -p "$INSTALL_DIR"

    # Back up existing install
    if [ -d "$INSTALL_DIR/$APP_BUNDLE" ]; then
      info "Backing up existing installation..."
      mv "$INSTALL_DIR/$APP_BUNDLE" "$INSTALL_DIR/${APP_BUNDLE}.bak.$(date +%s)"
    fi

    info "Extracting to $INSTALL_DIR/$APP_BUNDLE..."
    unzip -qo "$TMP_DIR/$ARTIFACT" -d "$INSTALL_DIR"

    # Remove quarantine flag (prevents Gatekeeper prompt even on notarized apps
    # when downloaded via curl)
    xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_BUNDLE" 2>/dev/null || true

    echo ""
    info "SpartaNode $FILE_VERSION installed to $INSTALL_DIR/$APP_BUNDLE"
    info "Open from Spotlight or ~/Applications."
    ;;
esac
