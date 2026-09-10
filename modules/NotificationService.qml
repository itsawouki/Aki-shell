pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "." as Modules

// Owns the desktop notification daemon and a one-at-a-time display queue.
// DynamicIsland just reads `current` and shows it for popupDuration.
Singleton {
    id: service

    readonly property int popupDuration: 4000 // ms

    property var queue: []       // Notification objects waiting their turn
    property var current: null   // the one currently on screen, or null

    function _tryShowNext() {
        if (service.current) return
        if (service.queue.length === 0) return
        const next = service.queue[0]
        service.queue = service.queue.slice(1)
        service.current = next
        popupTimer.restart()
    }

    function dismissCurrent() {
        service.current = null
        popupTimer.stop()
        service._tryShowNext()
    }

    function _playSound() {
        Quickshell.execDetached({
            command: ["sh", "-c",
                "for f in /usr/share/sounds/freedesktop/stereo/message-new-instant.oga " +
                "/usr/share/sounds/freedesktop/stereo/message.oga; do " +
                "[ -f \"$f\" ] && { paplay \"$f\" 2>/dev/null || pw-play \"$f\" 2>/dev/null; break; }; done"
            ]
        })
    }

    Timer {
        id: popupTimer
        interval: service.popupDuration
        onTriggered: service.dismissCurrent()
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true
            Modules.AudioService.duckForNotification()
            service._playSound()
            service.queue = service.queue.concat([notification])
            service._tryShowNext()

            notification.closed.connect(() => {
                if (service.current === notification) {
                    service.dismissCurrent()
                } else {
                    service.queue = service.queue.filter(n => n !== notification)
                }
            })
        }
    }
}
