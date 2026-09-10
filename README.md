# Aki-Shell

A custom Dynamic Island–style desktop shell for Hyprland, built with
[Quickshell](https://quickshell.org) (QML). Notch-based UI with panels for
media, audio, network, clipboard, notifications, workspaces, power, a movie/anime
library, music, YouTube channel stats, wallpaper, and Google Calendar sync.

> **Requires Hyprland with a `hyprland.lua` config.**
> If you're on the classic `hyprland.conf`, the shell still runs, but the
> installer can't wire up keybinds/autostart for you and a few Settings-panel
> features won't work. See [MANUAL_INSTALL.md](MANUAL_INSTALL.md).

## Install

```bash
git clone https://github.com/itsawouki/Aki-shell.git
cd Aki-Shell
./install.sh
```

The installer is a TUI — it checks your dependencies, checks your Hyprland
config format, copies the shell into `~/.config/Aki-Shell`, creates
`~/Videos/Movies` and `~/Music` if they don't exist, and leaves personal/local
files (movie library, theme, `.installed` marker) untouched.

## Dependencies

### Required
| Package | Used for |
|---|---|
| [`quickshell`](https://quickshell.org) | the shell engine itself |
| `hyprland` | window manager this shell is built for |
| `python3` | settings, YouTube stats, Google OAuth, movie library backend (stdlib only, no pip packages needed) |
| `curl` | Google OAuth token exchange/refresh |
| `jq` | music playlist parsing |
| `mpv` | music/video playback |
| `networkmanager` (`nmcli`) | network panel |
| `xdg-utils` (`xdg-open`) | Google sign-in browser launch, opening links |
| `wl-clipboard` | clipboard panel |
| `hyprlock` | lock button in the power menu |
| `kitty` | terminal anime search is launched in |
| `ani-cli` | anime search feature |
| `awww` | wallpaper get/set and accent-color-from-wallpaper sync |
| `imagemagick` | accent-color sampling from the current wallpaper |
| `nm-connection-editor` | "edit connection" in the network panel |
| a `sound-theme-freedesktop`-compatible setup + `pipewire-pulse`/`alsa-utils` (`paplay`/`pw-play`/`aplay`) | UI sound effects, notification sound |

Arch example, everything at once:
```bash
yay -S quickshell hyprland python jq mpv networkmanager xdg-utils \
       wl-clipboard hyprlock kitty ani-cli awww imagemagick \
       nm-connection-editor
```

## Google Calendar sync (optional)

Off by default. See [GOOGLE_CALENDAR_SETUP.md](GOOGLE_CALENDAR_SETUP.md) to
enable it — you'll create your own free Google Cloud OAuth credentials
(nothing to pay for, just a few clicks in Google Cloud Console).

## YouTube channel stats

Off by default. Open the Settings panel in the shell and enter your channel
ID and a YouTube Data API v3 key (get one free from Google Cloud Console) to
enable the subscriber/view counter.

## Hyprland (lua) wiring

The installer prints these for you, but for reference:
```lua
hyprland.exec_once('qs -c Aki-Shell -p "~/.config/Aki-Shell"')
hyprland.bind('SUPER', 'D', 'exec', 'qs -c Aki-Shell ipc call island toggle')
```

## What the installer won't touch

Personal/local files are excluded from install and from this repo (see
`.gitignore`): your movie library data, theme/clock/YouTube settings, Google
credentials/tokens, and the first-run `.installed` marker. The installer
creates safe defaults for theme/clock/YouTube settings on first run; you
configure everything through the shell's own Settings panel.
