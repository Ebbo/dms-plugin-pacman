# dms-plugin-pacman

A DMS plugin for monitoring and installing Arch Linux package updates from official repositories and the AUR.

## Features

- Monitor updates from both official Arch repos and the AUR
- Automatic detection of AUR helpers (yay / paru)
- Multiple update check methods (auto, checkupdates, helper)
- Configurable periodic background checks (default: 30 min)
- Status bar indicator with color-coded states (green = up to date, yellow = updates available, red = error)
- Launch system updates directly from the UI in your preferred terminal
- Toast notifications when new updates are found

## Requirements

- **DMS** >= 1.4.0
- **pacman** (Arch Linux package manager)
- **pacman-contrib** (optional, provides `checkupdates` for safe database syncing)
- **yay** or **paru** (optional, for AUR support)

## Installation

Place the plugin directory under your DMS plugins folder:

```
~/.config/dms/plugins/dms-plugin-pacman/
```

## Configuration

Settings are available through the DMS plugin settings UI:

| Setting | Description | Default |
|---|---|---|
| `preferredHelper` | AUR helper to use (`auto` / `yay` / `paru`) | `auto` |
| `terminal` | Terminal emulator command (e.g. `foot`, `kitty`, `alacritty -e`) | - |
| `checkMethod` | How to check for updates (`auto` / `checkupdates` / `helper`) | `auto` |
| `checkInterval` | Check frequency in minutes (minimum 5) | `30` |
| `showVersions` | Display version numbers in the update list | `true` |
| `notifyOnUpdates` | Show a toast notification when updates are found | `true` |

### Check methods

- **auto** - Uses `checkupdates` for official repos and the AUR helper for AUR packages only.
- **checkupdates** - Explicitly uses `checkupdates` for official repos plus the AUR helper for AUR packages.
- **helper** - Uses the AUR helper for everything, falling back to `checkupdates` if needed.

## License

MIT
