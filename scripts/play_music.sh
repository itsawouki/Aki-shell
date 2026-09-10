#!/bin/bash

MUSIC_DIR="$HOME/Music"
JSON_FILE="$MUSIC_DIR/youtube_playlists.json"
SCRIPT_NAME="myshell-music"

case "$1" in
    --list)
        # Standard output must be clean so Quickshell can read it
        if [ -d "$MUSIC_DIR" ]; then
            find "$MUSIC_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\tlocal\n" | sort
        fi
        if [ -f "$JSON_FILE" ] && command -v jq &> /dev/null; then
            jq -r '.[] | "\(.name)\tyt\t\(.url)"' "$JSON_FILE" 2>/dev/null
        fi
        ;;

    --play)
        # Log play events for debugging without breaking --list
        LOG_FILE="/tmp/myshell_debug.log"
        echo "=== Playing: $2 ===" >> "$LOG_FILE"

        NAME="$2"
        [ -z "$NAME" ] && exit 1

        pkill -f "$SCRIPT_NAME"
        sleep 0.2

        # Check YouTube playlist from JSON
        URL=""
        if [ -f "$JSON_FILE" ] && command -v jq &> /dev/null; then
            URL=$(jq -r --arg name "$NAME" '.[] | select(.name == $name) | .url' "$JSON_FILE" 2>/dev/null)
        fi

        if [ -n "$URL" ]; then
            nohup mpv --no-video --ytdl-format=bestaudio --ytdl-raw-options=yes-playlist= "$URL" --title="$SCRIPT_NAME" > /tmp/myshell_mpv.log 2>&1 &
        else
            if [ "$NAME" == "Music" ]; then
                TRACKS=$(find "$MUSIC_DIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.opus" \))
            else
                TRACKS=$(find "$MUSIC_DIR/$NAME" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.opus" \))
            fi

            if [ -n "$TRACKS" ]; then
                PLAYLIST="/tmp/myshell_current.m3u"
                echo "$TRACKS" | shuf > "$PLAYLIST"
                nohup mpv --no-video --playlist="$PLAYLIST" --title="$SCRIPT_NAME" > /tmp/myshell_mpv.log 2>&1 &
            fi
        fi
        ;;

    --stop)
        pkill -f "$SCRIPT_NAME"
        ;;
esac
