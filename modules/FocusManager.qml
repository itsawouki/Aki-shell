pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    property int workMinutes: 25
    property int breakMinutes: 5
    property int totalCycles: 4
    property int currentCycle: 1
    property bool isBreak: false
    property bool running: false
    property int secondsRemaining: workMinutes * 60

    // Audio path for completed sessions
    property string completionSound: "/usr/share/sounds/freedesktop/stereo/complete.oga"

    function playSound() {
        Quickshell.execDetached({
            command: ["paplay", root.completionSound]
        })
    }

    function toggleTimer() {
        if (!running && secondsRemaining <= 0) {
            secondsRemaining = (isBreak ? breakMinutes : workMinutes) * 60
        }
        running = !running
    }

    function resetTimer() {
        running = false
        currentCycle = 1
        isBreak = false
        secondsRemaining = workMinutes * 60
    }

    function formatTime(totalSecs) {
        let m = Math.floor(totalSecs / 60)
        let s = totalSecs % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    readonly property string formattedTime: formatTime(secondsRemaining)

    property Timer _timer: Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.secondsRemaining > 1) {
                root.secondsRemaining--
            } else {
                root.secondsRemaining = 0
                root.playSound() // Play sound when session or break finishes

                if (!root.isBreak) {
                    root.isBreak = true
                    root.secondsRemaining = root.breakMinutes * 60
                } else {
                    if (root.currentCycle < root.totalCycles) {
                        root.currentCycle++
                        root.isBreak = false
                        root.secondsRemaining = root.workMinutes * 60
                    } else {
                        root.running = false
                        root.currentCycle = 1
                        root.isBreak = false
                        root.secondsRemaining = root.workMinutes * 60
                    }
                }
            }
        }
    }
}
