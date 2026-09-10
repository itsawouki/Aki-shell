# Manual install

Use this guide if `install.sh` failed partway, isn't supported on your
system, or you'd simply rather set things up by hand. It also covers
`hyprland.conf` wiring, since the installer only automates that for the
**lua** config.

## 1. Copy the shell files

Copy the shell into `~/.config/Aki-Shell`, skipping the personal/local files
the installer normally excludes:

```bash
mkdir -p ~/.config/Aki-Shell
cp -r modules scripts assets shell.qml ~/.config/Aki-Shell/
chmod +x ~/.config/Aki-Shell/scripts/*.sh
chmod +x ~/.config/Aki-Shell/scripts/*.py
```

Do **not** copy these if they exist in your checkout — they're personal/local
data, not part of the shell itself:
`.installed`, `movies_data.json`, `movies_data.json.lock`,
`theme-settings.json`, `clock-settings.json`, `yt-settings.json`,
`google-credentials.json`, `google-tokens.json`, `debugging.sh`.

## 2. Create default local settings

```bash
echo '{"accentColor":"#6e9466","syncWithWallpaper":true}' > ~/.config/Aki-Shell/theme-settings.json
echo '{"format":"12h","showSeconds":false}' > ~/.config/Aki-Shell/clock-settings.json
echo '{"channelId":"","apiKey":"","subGoal":2000}' > ~/.config/Aki-Shell/yt-settings.json
```

You'll fill in the YouTube fields later via the shell's Settings panel — see
the README's YouTube API tutorial.

## 3. Create media folders

```bash
mkdir -p ~/Videos/Movies ~/Music
```

## 4. Check dependencies

Make sure you have the required packages listed in the README's Dependencies
table (`quickshell`, `hyprland`, `python3`, `curl`, `jq`, `mpv`,
`networkmanager`, `xdg-utils`, plus whichever optional ones you want the
matching features for).

## 5. Wire up Hyprland

### If you use `hyprland.lua`

```lua
hyprland.exec_once('qs -c Aki-Shell -p "~/.config/Aki-Shell"')
hyprland.bind('SUPER', 'D', 'exec', 'qs -c Aki-Shell ipc call island toggle')
```

### If you use `hyprland.conf`

Add to `~/.config/hypr/hyprland.conf`:
```
exec-once = qs -c Aki-Shell -p ~/.config/Aki-Shell
```

The shell is controlled entirely through `qs ipc call <target> <action>`.
Add whichever of these you want:

```
# Toggle the main notch (launcher)
bind = SUPER, D, exec, qs -c Aki-Shell ipc call island toggle

# Individual panels — swap keys to whatever you like
bind = SUPER, A, exec, qs -c Aki-Shell ipc call audio toggle
bind = SUPER, M, exec, qs -c Aki-Shell ipc call music toggle
bind = SUPER, N, exec, qs -c Aki-Shell ipc call network toggle
bind = SUPER, V, exec, qs -c Aki-Shell ipc call clipboard toggle
bind = SUPER, S, exec, qs -c Aki-Shell ipc call settings toggle
bind = SUPER, W, exec, qs -c Aki-Shell ipc call wallpaper toggle
bind = SUPER, P, exec, qs -c Aki-Shell ipc call power toggle
bind = SUPER, Y, exec, qs -c Aki-Shell ipc call youtube toggle
bind = SUPER, F, exec, qs -c Aki-Shell ipc call movie toggle
```

Every target above also supports `open` and `close` instead of `toggle`, if
you'd rather bind those separately (e.g. one key to open, `Escape` handled
inside the shell to close).

**Note:** Settings-panel features that need to read or write Hyprland's own
config file directly rely on the lua config API and won't function under
`hyprland.conf`. Everything else — media control, notifications, clipboard,
network, audio, notch panels — works the same either way, since those talk
to Hyprland through `hyprctl` and system tools, not through the config file.

## 6. Run it

```bash
qs -c Aki-Shell -p ~/.config/Aki-Shell
```

Reload Hyprland (or log out/in) once `exec-once` is added so it starts
automatically going forward.

