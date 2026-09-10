#!/usr/bin/env bash
# Aki-Shell installer — Hyprland (lua config only)
set -uo pipefail

# ---------------------------------------------------------------------------
# Colors / styling
# ---------------------------------------------------------------------------
C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_BOLD=$'\033[1m'
C_ACCENT=$'\033[38;5;114m'   # soft green, matches shell's default accent
C_WARN=$'\033[38;5;179m'
C_ERR=$'\033[38;5;203m'
C_OK=$'\033[38;5;114m'
C_INFO=$'\033[38;5;110m'

TERM_WIDTH=$(tput cols 2>/dev/null || echo 70)
BOX_WIDTH=$(( TERM_WIDTH > 78 ? 78 : TERM_WIDTH - 2 ))
[ "$BOX_WIDTH" -lt 40 ] && BOX_WIDTH=40

hr() { printf "%s" "$C_DIM"; printf '─%.0s' $(seq 1 "$BOX_WIDTH"); printf "%s\n" "$C_RESET"; }

box_top()    { printf "%s╭" "$C_ACCENT"; printf '─%.0s' $(seq 1 $((BOX_WIDTH-2))); printf "╮%s\n" "$C_RESET"; }
box_bottom() { printf "%s╰" "$C_ACCENT"; printf '─%.0s' $(seq 1 $((BOX_WIDTH-2))); printf "╯%s\n" "$C_RESET"; }
box_line() {
    local text="$1"
    local plain
    plain=$(printf "%s" "$text" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local pad=$(( BOX_WIDTH - 4 - ${#plain} ))
    [ "$pad" -lt 0 ] && pad=0
    printf "%s│ %s%*s %s│%s\n" "$C_ACCENT" "$C_RESET$text" "$pad" "" "$C_ACCENT" "$C_RESET"
}

title() {
    echo
    box_top
    box_line "${C_BOLD}$1${C_RESET}"
    box_bottom
}

step() { echo; printf "%s▸ %s%s\n" "$C_ACCENT" "$C_RESET$1" ""; }
ok()   { printf "  %s✓%s %s\n" "$C_OK" "$C_RESET" "$1"; }
warn() { printf "  %s!%s %s\n" "$C_WARN" "$C_RESET" "$1"; }
err()  { printf "  %s✗%s %s\n" "$C_ERR" "$C_RESET" "$1"; }
info() { printf "  %s·%s %s\n" "$C_INFO" "$C_RESET" "$1"; }

confirm() {
    # confirm "question" [default: Y/n]
    local prompt="$1"
    local ans
    printf "  %s?%s %s %s[Y/n]%s " "$C_ACCENT" "$C_RESET" "$prompt" "$C_DIM" "$C_RESET"
    read -r ans
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

spinner() {
    # spinner "message" -- runs while pid $1 is alive
    local pid=$1 msg=$2
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    tput civis 2>/dev/null
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % ${#frames} ))
        printf "\r  %s%s%s %s" "$C_ACCENT" "${frames:$i:1}" "$C_RESET" "$msg"
        sleep 0.08
    done
    tput cnorm 2>/dev/null
    printf "\r\033[K"
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/Aki-Shell"
HYPR_CONF_DIR="$HOME/.config/hypr"

# Files/dirs that are personal or machine-specific and must never be copied
# by the installer, even if present in the repo checkout.
EXCLUDE_FILES=(
    ".installed"
    "movies_data.json"
    "movies_data.json.lock"
    "theme-settings.json"
    "clock-settings.json"
    "yt-settings.json"
    "google-credentials.json"
    "google-tokens.json"
    "debugging.sh"
)

# ---------------------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------------------
clear
title "Aki-Shell installer"
echo
echo "  A Quickshell-based Dynamic Island shell for Hyprland."
echo

# ---------------------------------------------------------------------------
# 1. Hyprland config format check — lua vs conf
# ---------------------------------------------------------------------------
step "Checking your Hyprland config format"

HAS_LUA=0
HAS_CONF=0
[ -f "$HYPR_CONF_DIR/hyprland.lua" ] && HAS_LUA=1
[ -f "$HYPR_CONF_DIR/hyprland.conf" ] && HAS_CONF=1

if [ "$HAS_LUA" -eq 1 ]; then
    ok "Found hyprland.lua — Aki-Shell's automatic setup is fully supported"
elif [ "$HAS_CONF" -eq 1 ]; then
    warn "You're using the classic hyprland.conf, not the lua config"
    echo
    echo "  Aki-Shell's automated keybind/startup wiring only supports Hyprland's"
    echo "  ${C_BOLD}lua${C_RESET} config format. With a .conf setup:"
    echo "    - keybinds and autostart will ${C_BOLD}not${C_RESET} be added automatically"
    echo "    - some Settings-panel features that write back to your Hyprland config"
    echo "      will not work"
    echo
    echo "  The shell itself will still run. See ${C_BOLD}MANUAL_INSTALL.md${C_RESET} in this repo"
    echo "  for the keybinds/exec-once lines to add to hyprland.conf yourself."
    echo
    if ! confirm "Continue anyway?"; then
        echo; info "Installation cancelled."; exit 0
    fi
else
    warn "No hyprland.lua or hyprland.conf found at $HYPR_CONF_DIR"
    info "Continuing — but Aki-Shell is built for Hyprland and expects one of these."
    if ! confirm "Continue anyway?"; then
        echo; info "Installation cancelled."; exit 0
    fi
fi

# ---------------------------------------------------------------------------
# 2. Dependency check
# ---------------------------------------------------------------------------
step "Checking dependencies"

# name : check-command
REQUIRED_BINS=(
    "quickshell:quickshell"
    "hyprland:Hyprctl"
    "python3:python3"
    "curl:curl"
    "jq:jq"
    "mpv:mpv"
)

MISSING=()

check_bin() {
    command -v "$1" >/dev/null 2>&1
}

# Hyprland itself isn't a "binary to check" in the usual sense (checked via hyprctl)
if check_bin quickshell; then ok "quickshell"; else MISSING+=("quickshell"); err "quickshell (required — this is the shell engine)"; fi
if check_bin hyprctl; then ok "hyprland (hyprctl found)"; else MISSING+=("hyprland"); err "hyprland (required)"; fi
if check_bin python3; then ok "python3"; else MISSING+=("python3"); err "python3 (required — settings, YouTube stats, Google OAuth, movie library)"; fi
if check_bin curl; then ok "curl"; else MISSING+=("curl"); err "curl (required — Google OAuth token exchange)"; fi
if check_bin jq; then ok "jq"; else MISSING+=("jq"); err "jq (required — music playlist parsing)"; fi
if check_bin mpv; then ok "mpv"; else MISSING+=("mpv"); err "mpv (required — music/video playback)"; fi
if check_bin nmcli; then ok "nmcli (NetworkManager)"; else MISSING+=("networkmanager"); err "nmcli (required — network panel)"; fi
if check_bin xdg-open; then ok "xdg-open"; else MISSING+=("xdg-utils"); err "xdg-open (required — Google sign-in, links)"; fi

echo
info "Optional (feature-specific, shell still runs without them):"
check_bin wl-copy   && ok "wl-clipboard"        || warn "wl-clipboard missing — clipboard panel won't work"
check_bin hyprlock   && ok "hyprlock"           || warn "hyprlock missing — lock button in power menu won't work"
check_bin kitty      && ok "kitty"              || warn "kitty missing — anime search (ani-cli) launches in kitty, needs it"
check_bin ani-cli    && ok "ani-cli"            || warn "ani-cli missing — anime search feature won't work"
check_bin awww       && ok "awww"               || warn "awww missing — wallpaper get/set and accent-color sync won't work"
check_bin convert    && ok "imagemagick"        || warn "imagemagick (convert) missing — wallpaper-based accent color sync won't work"
check_bin nm-connection-editor && ok "nm-connection-editor" || warn "nm-connection-editor missing — 'edit connection' in network panel won't work"
check_bin paplay || check_bin pw-play || check_bin aplay \
    && ok "audio playback (paplay/pw-play/aplay)" \
    || warn "no paplay/pw-play/aplay found — UI sound effects won't play"

if [ ${#MISSING[@]} -gt 0 ]; then
    echo
    err "Missing required dependencies: ${MISSING[*]}"
    echo
    echo "  Install them first (Arch example):"
    echo "  ${C_DIM}yay -S ${MISSING[*]}${C_RESET}"
    echo
    if ! confirm "Continue installing anyway?"; then
        echo; info "Installation cancelled. Install the missing packages and re-run."; exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 3. Install files
# ---------------------------------------------------------------------------
step "Installing to $CONFIG_DIR"

mkdir -p "$CONFIG_DIR"

is_excluded() {
    local base
    base="$(basename "$1")"
    local _ex
    for _ex in "${EXCLUDE_FILES[@]}"; do
        [ "$base" == "$_ex" ] && return 0
    done
    return 1
}

copy_tree() {
    local src="$1" dst="$2"
    mkdir -p "$dst"
    local entry base
    for entry in "$src"/*; do
        [ -e "$entry" ] || continue
        base="$(basename "$entry")"
        if [ -d "$entry" ]; then
            copy_tree "$entry" "$dst/$base"
        else
            if is_excluded "$entry"; then
                info "Skipping personal/local file: $base"
                continue
            fi
            cp -f "$entry" "$dst/$base"
        fi
    done
}

(
    copy_tree "$SCRIPT_DIR/modules" "$CONFIG_DIR/modules"
    copy_tree "$SCRIPT_DIR/scripts" "$CONFIG_DIR/scripts"
    copy_tree "$SCRIPT_DIR/assets"  "$CONFIG_DIR/assets"
    cp -f "$SCRIPT_DIR/shell.qml" "$CONFIG_DIR/shell.qml"
    chmod +x "$CONFIG_DIR/scripts/"*.sh 2>/dev/null
    chmod +x "$CONFIG_DIR/scripts/"*.py 2>/dev/null
) &
COPY_PID=$!
spinner "$COPY_PID" "Copying shell files..."
wait "$COPY_PID"
ok "Shell files installed to $CONFIG_DIR"

# ---------------------------------------------------------------------------
# 4. Ensure user data directories exist (Movies / Music)
# ---------------------------------------------------------------------------
step "Checking media folders"

MOVIES_DIR="$HOME/Videos/Movies"
MUSIC_DIR="$HOME/Music"

if [ -d "$MOVIES_DIR" ]; then
    ok "$MOVIES_DIR already exists"
else
    mkdir -p "$MOVIES_DIR"
    ok "Created $MOVIES_DIR"
fi

if [ -d "$MUSIC_DIR" ]; then
    ok "$MUSIC_DIR already exists"
else
    mkdir -p "$MUSIC_DIR"
    ok "Created $MUSIC_DIR"
fi

# ---------------------------------------------------------------------------
# 5. First-run defaults for personal config files (not copied from repo,
#    since these are excluded — create empty/sane defaults instead)
# ---------------------------------------------------------------------------
step "Setting up local config"

[ -f "$CONFIG_DIR/theme-settings.json" ] || echo '{"accentColor":"#6e9466","syncWithWallpaper":true}' > "$CONFIG_DIR/theme-settings.json"
[ -f "$CONFIG_DIR/clock-settings.json" ] || echo '{"format":"12h","showSeconds":false}' > "$CONFIG_DIR/clock-settings.json"
[ -f "$CONFIG_DIR/yt-settings.json" ]    || echo '{"channelId":"","apiKey":"","subGoal":2000}' > "$CONFIG_DIR/yt-settings.json"
ok "Default local settings created (edit in-app via the Settings panel)"

# ---------------------------------------------------------------------------
# 6. Hyprland lua wiring (only if lua config present)
# ---------------------------------------------------------------------------
if [ "$HAS_LUA" -eq 1 ]; then
    step "Hyprland (lua) integration"
    info "Add the following to your hyprland.lua if not already present:"
    echo
    echo "  ${C_DIM}hyprland.exec_once('qs -c Aki-Shell -p \"$CONFIG_DIR\"')${C_RESET}"
    echo "  ${C_DIM}hyprland.bind('SUPER', 'D', 'exec', 'qs -c Aki-Shell ipc call island toggle')${C_RESET}"
    echo
    info "See README.md for the full list of IPC calls used by keybinds."
elif [ "$HAS_CONF" -eq 1 ]; then
    step "Hyprland (.conf) integration"
    warn "Automatic wiring skipped — you're on hyprland.conf."
    info "See MANUAL_INSTALL.md for the exec-once / bind lines to add by hand."
fi

# ---------------------------------------------------------------------------
# 7. Google Calendar (optional)
# ---------------------------------------------------------------------------
step "Google Calendar sync (optional)"
info "Skipped — this needs your own Google Cloud credentials."
info "See GOOGLE_CALENDAR_SETUP.md to enable it later."

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo
box_top
box_line "${C_BOLD}${C_OK}Install complete${C_RESET}"
box_bottom
echo
echo "  Run it manually to test:"
echo "  ${C_DIM}qs -c Aki-Shell -p \"$CONFIG_DIR\"${C_RESET}"
echo
[ "$HAS_CONF" -eq 1 ] && [ "$HAS_LUA" -eq 0 ] && echo "  ${C_WARN}Remember: see MANUAL_INSTALL.md for hyprland.conf wiring.${C_RESET}" && echo
