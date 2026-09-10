pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/Aki-Shell"
    readonly property string markerPath: configDir + "/.installed"
    readonly property string sfxDir: configDir + "/assets/sfx"

    property bool checked: false
    property bool isFirstRun: false
    property string stage: "hero"
    property int revealedCount: 0
    property int totalFeatures: 8
    property string userName: Quickshell.env("USER") ?? ""

    readonly property string greetingName: {
        if (userName.length === 0) return "there"
        return userName.charAt(0).toUpperCase() + userName.slice(1)
    }

    Component.onCompleted: {
        markerCheckProc.running = true
        if (userName.length === 0) whoamiProc.running = true
    }

    property Process markerCheckProc: Process {
        command: ["sh", "-c", "test -f '" + root.markerPath + "'"]
        onExited: (code) => {
            root.checked = true
            root.isFirstRun = (code !== 0)
        }
    }

    property Process whoamiProc: Process {
        command: ["sh", "-c", "whoami"]
        stdout: SplitParser {
            onRead: data => {
                const n = data.trim()
                if (n.length > 0 && root.userName.length === 0) root.userName = n
            }
        }
    }

    function completeHold() {
        if (root.stage !== "hero") return
        root.stage = "features"
        root.revealedCount = 0
        root.revealTimer.restart()
    }

    function finish() {
        if (root.stage === "leaving" || root.stage === "done") return
        root.stage = "leaving"
        root.revealTimer.stop()
        leaveTimer.restart()
    }

    function open() {
        if (!root.isFirstRun || root.stage === "leaving") return
        root.stage = "hero"
    }

    function close() {
        root.finish()
    }

    function reset() {
        resetProc.running = true
        root.checked = true
        root.isFirstRun = true
        root.stage = "hero"
        root.revealedCount = 0
    }

    property Process resetProc: Process {
        command: ["sh", "-c", "rm -f '" + root.markerPath + "'"]
    }

    property Timer revealTimer: Timer {
        interval: 800
        repeat: true
        onTriggered: {
            if (root.revealedCount >= root.totalFeatures) {
                root.revealTimer.stop()
                return
            }
            root.revealedCount++
            if (root.revealedCount >= root.totalFeatures) root.revealTimer.stop()
        }
    }

    property Timer leaveTimer: Timer {
        interval: 520
        onTriggered: {
            root._writeMarker()
            root.isFirstRun = false
            root.stage = "done"
        }
    }

    function _writeMarker() {
        writeProc.command = ["sh", "-c",
            "mkdir -p '" + root.configDir + "' && printf 'installed %s\\n' \"$(date +%s)\" > '" + root.markerPath + "'"]
        writeProc.running = true
    }

    property Process writeProc: Process {}

    property real _lastSfxAt: 0
    function playSfx(name) {
        const now = Date.now()
        if (now - _lastSfxAt < 280) return
        _lastSfxAt = now
        sfxProc.command = ["sh", "-c",
            "P='" + root.sfxDir + "/" + name + ".wav'; [ -f \"$P\" ] && " +
            "{ paplay \"$P\" 2>/dev/null || pw-play \"$P\" 2>/dev/null || aplay -q \"$P\" 2>/dev/null; }"]
        sfxProc.running = true
    }

    property Process sfxProc: Process {}

    function ensureSfx() {
        genSfxProc.command = ["sh", "-c",
            "[ -f '" + root.sfxDir + "/unlock.wav' ] && [ -f '" + root.sfxDir + "/press.wav' ] && exit 0; " +
            "mkdir -p '" + root.sfxDir + "' && python3 '" + root.configDir + "/scripts/gen_sfx.py' '" + root.sfxDir + "' 2>/dev/null"]
        genSfxProc.running = true
    }

    property Process genSfxProc: Process {}
}
