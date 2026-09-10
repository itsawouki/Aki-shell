pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Hyprland
import QtQuick
import "." as Modules

QtObject {
    id: root

    property var queue: []
    property int queueVersion: 0
    property var current: null
    readonly property bool hasCurrent: current !== null
    property int notifDurationMs: 4000

    function _playSound() {
        Quickshell.execDetached({
            command: ["sh", "-c",
                "for f in /usr/share/sounds/freedesktop/stereo/message-new-instant.oga " +
                "/usr/share/sounds/freedesktop/stereo/message.oga; do " +
                "[ -f \"$f\" ] && { paplay \"$f\" 2>/dev/null || pw-play \"$f\" 2>/dev/null; break; }; done"
            ]
        })
    }

    property Timer _dismissTimer: Timer {
        interval: root.notifDurationMs
        onTriggered: root.advance()
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: false

        imageSupported: true
        bodyImagesSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            Modules.AudioService.duckForNotification()
            root._playSound()
            root.queue.push(notification)
            root.queueVersion++
            root._advanceIfIdle()
        }
    }

    function _advanceIfIdle() {
        if (root.current === null && root.queue.length > 0) {
            root.current = root.queue.shift()
            root.queueVersion++
            root._dismissTimer.restart()
        }
    }

    function advance() {
        root._dismissTimer.stop()
        root.current = null
        root._advanceIfIdle()
    }

    function dismissCurrent() {
        if (root.current) root.current.dismiss()
        advance()
    }

    function activateCurrent() {
        if (!root.current) return
        const appName = root.current.appName
        if (appName && appName.length > 0) {
            console.log("[NotificationQueue] attempting to focus window, class:", appName)
            Hyprland.dispatch("focuswindow class:" + appName)
            if (appName !== appName.toLowerCase()) {
                Hyprland.dispatch("focuswindow class:" + appName.toLowerCase())
            }
        }
        dismissCurrent()
    }
}
