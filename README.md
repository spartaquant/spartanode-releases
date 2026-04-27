# SpartaNode Desktop

Multi-user GUI orchestrator for Claude Code tasks.
Download the desktop app for Windows, macOS, or Linux.

## Quick install

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.sh | bash
```

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.ps1 | iex
```

## Manual download

Go to the [Releases](https://github.com/spartaquant/spartanode-releases/releases)
page and download the artifact for your platform:

| OS | Consumer | Enterprise |
|---|---|---|
| **Windows** | `SpartaNode-Setup-X.Y.Z.exe` (installer) | `SpartaNode-X.Y.Z-win-x64.zip` (portable) |
| **macOS** | `SpartaNode-X.Y.Z.dmg` | `SpartaNode-X.Y.Z-mac-x64.zip` / `mac-arm64.zip` |
| **Linux** | `SpartaNode-X.Y.Z.AppImage` | `SpartaNode-X.Y.Z-linux.tar.gz` |

## Verify downloads

Every release includes `SHA256SUMS.txt` (checksums) and
`SHA256SUMS.txt.asc` (GPG signature). The install scripts verify
these automatically.

To verify manually:

```bash
# Import the public key
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/keys/spartanode-releases.asc | gpg --import

# Verify the signature
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt

# Verify the artifact
sha256sum -c SHA256SUMS.txt
```

GPG key fingerprint: `(to be published)`

## Update

Re-run the install script to update to the latest version. The app
also checks for updates automatically on launch (consumer installs).

To update via script:

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/install.ps1 | iex
```

## Uninstall

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.sh | bash

# Windows
irm https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.ps1 | iex
```

Add `--purge` (Linux/macOS) or `-Purge` (Windows) to also remove user
data.

## Support

- Issues: https://github.com/spartaquant/spartanode-releases/issues
- Security: see [SECURITY.md](SECURITY.md)
