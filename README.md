# Aki-Shell

A custom Dynamic Island–style desktop shell for Hyprland, built with
[Quickshell](https://quickshell.org) (QML). Notch-based UI with panels for
media, audio, network, clipboard, notifications, workspaces, power, a movie/anime
library, music, YouTube channel stats, wallpaper, and Google Calendar sync.

> **Requires Hyprland with a `hyprland.lua` config.**
> If you're on the classic `hyprland.conf`, the shell still runs, but the
> installer can't wire up keybinds/autostart for you and a few Settings-panel
> features won't work. See [MANUAL_INSTALL.md](MANUAL_INSTALL.md).

## Screenshots

<p align="center">
  <img src="assets/screenshot-1.png" width="400">
  <img src="assets/screenshot-2.png" width="400">
</p>

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

**If the installer doesn't work for you** (fails partway, unsupported shell,
or you'd rather do it by hand), see [MANUAL_INSTALL.md](MANUAL_INSTALL.md)
for step-by-step manual setup.

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

Off by default. Shows your subscriber/view counter in the shell using the
free YouTube Data API v3.

### Getting a YouTube Data API key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/) and
   sign in.
2. Create a new project (top bar → project dropdown → **New Project**), or
   pick an existing one.
3. In the search bar, search for **YouTube Data API v3** and open it.
4. Click **Enable**.
5. Go to **APIs & Services → Credentials** (left sidebar).
6. Click **+ Create Credentials → API key**.
7. Copy the key that's generated.
8. *(Recommended)* Click **Edit API key** and under **API restrictions**,
   restrict it to **YouTube Data API v3** only — this limits what the key
   can be used for if it ever leaks.

### Getting your channel ID

1. Go to [youtube.com](https://youtube.com) and open your channel.
2. Click your profile icon → **Your channel**.
3. The channel ID is in the URL: `youtube.com/channel/<THIS_PART>`.
   - If your channel uses a custom handle URL instead (`youtube.com/@yourname`),
     go to **YouTube Studio → Settings → Channel → Basic info** — your
     channel ID is listed there.

### Adding them to Aki-Shell

Open the Settings panel in the shell and paste in your channel ID and API
key. This is stored locally in `~/.config/Aki-Shell/yt-settings.json` and is
never shared anywhere else — keep that file private and don't commit it if
you fork this repo (it's already in `.gitignore`).

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
