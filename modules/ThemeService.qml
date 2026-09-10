pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/Aki-Shell"
    readonly property string themePath: configDir + "/theme-settings.json"

    property color accentColor: "#8ab4f8"
    readonly property string accentHex: "#" +
        Math.round(accentColor.r * 255).toString(16).padStart(2, "0") +
        Math.round(accentColor.g * 255).toString(16).padStart(2, "0") +
        Math.round(accentColor.b * 255).toString(16).padStart(2, "0")
    property bool syncWithWallpaper: false
    property string lastWallpaperPath: ""

    Component.onCompleted: _load()

    function _load() { loadProc.running = true }

    function _save() {
        const payload = JSON.stringify({
            accentColor: accentHex,
            syncWithWallpaper: syncWithWallpaper
        })
        saveProc.command = ["sh", "-c",
            "mkdir -p '" + configDir + "' && cat > '" + themePath + "' << 'EOF'\n" +
            payload + "\nEOF\n"]
        saveProc.running = true
    }

    function setColor(hex) {
        accentColor = hex
        _save()
    }

    function colorWithAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function accentDimmed(factor) {
        return Qt.darker(accentColor, factor)
    }

    function setSyncWithWallpaper(v) {
        syncWithWallpaper = v
        _save()
        wallpaperPoll.restart()
        if (v) _extractWallpaperColor()
    }

    function _extractWallpaperColor() {
        wallpaperProc.running = true
    }

    // Poll awww for wallpaper changes every 3 seconds
    property Timer wallpaperPoll: Timer {
        id: wallpaperPoll
        interval: 3000
        repeat: true
        running: root.syncWithWallpaper
        onTriggered: wallpaperQueryProc.running = true
    }

    property Process loadProc: Process {
        command: ["sh", "-c", "cat '" + root.themePath + "' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const p = JSON.parse(data)
                    root.accentColor = p.accentColor ?? "#8ab4f8"
                    root.syncWithWallpaper = p.syncWithWallpaper ?? false
                } catch (e) {}
            }
        }
    }

    property Process saveProc: Process {}

    // Lightweight: just get the current wallpaper path
    property Process wallpaperQueryProc: Process {
        command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                const path = data.trim()
                if (path.length > 0 && path !== root.lastWallpaperPath) {
                    root.lastWallpaperPath = path
                    root._extractWallpaperColor()
                }
            }
        }
    }

    // Heavy: extract dominant color from the wallpaper image
    property Process wallpaperProc: Process {
        command: ["sh", "-c",
            "WP=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1); " +
            "if [ -z \"$WP\" ] || [ ! -f \"$WP\" ]; then exit 1; fi; " +
            "convert \"$WP\" -resize 1x1! -format '%[fx:mean.r*255] %[fx:mean.g*255] %[fx:mean.b*255]' info: 2>/dev/null"
        ]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(" ")
                if (parts.length >= 3) {
                    const r = Math.round(parseFloat(parts[0]))
                    const g = Math.round(parseFloat(parts[1]))
                    const b = Math.round(parseFloat(parts[2]))
                    if (!isNaN(r) && !isNaN(g) && !isNaN(b)) {
                        root.accentColor = "#" +
                            r.toString(16).padStart(2, "0") +
                            g.toString(16).padStart(2, "0") +
                            b.toString(16).padStart(2, "0")
                        root._save()
                    }
                }
            }
        }
    }
}
