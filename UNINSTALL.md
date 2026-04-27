# Uninstalling SpartaNode Desktop

## Quick uninstall

### Windows

```powershell
# Run the uninstall script
irm https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.ps1 | iex
```

Or manually:
1. Delete `%LOCALAPPDATA%\SpartaNode\`
2. Delete shortcuts from Desktop and Start Menu
3. Optionally delete user data: `%APPDATA%\spartanode-desktop\`

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.sh | bash
```

Or manually:
1. Delete `~/.local/share/SpartaNode/`
2. Delete `~/.local/share/applications/spartanode.desktop`
3. Optionally delete user data: `~/.config/spartanode-desktop/`

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.sh | bash
```

Or manually:
1. Delete `~/Applications/SpartaNode.app`
2. Optionally delete user data: `~/Library/Application Support/spartanode-desktop/`

## What gets removed

| Component | Location | Removed by default |
|-----------|----------|-------------------|
| Application binary | Platform-specific (see above) | Yes |
| Desktop shortcut | Desktop / Start Menu / .desktop file | Yes |
| User data (database, settings) | Platform-specific (see above) | No |
| code-server data | Inside user data dir | No |

## Purge user data

To also remove your database, settings, and all local project data:

```bash
# Linux/macOS
uninstall.sh --purge

# Windows
uninstall.ps1 -Purge
```

**Warning:** This permanently deletes your local SpartaNode database
including all projects, tasks, and Gantt charts that haven't been
synced to the cloud.

## Verifying removal

After uninstalling, verify nothing remains:

```bash
# Linux
ls ~/.local/share/SpartaNode/ 2>/dev/null && echo "Still present" || echo "Clean"
ls ~/.config/spartanode-desktop/ 2>/dev/null && echo "Data remains" || echo "Clean"

# macOS
ls ~/Applications/SpartaNode.app 2>/dev/null && echo "Still present" || echo "Clean"
ls ~/Library/Application\ Support/spartanode-desktop/ 2>/dev/null && echo "Data remains" || echo "Clean"
```

```powershell
# Windows
Test-Path "$env:LOCALAPPDATA\SpartaNode" | % { if ($_) { "Still present" } else { "Clean" } }
Test-Path "$env:APPDATA\spartanode-desktop" | % { if ($_) { "Data remains" } else { "Clean" } }
```
