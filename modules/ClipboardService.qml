pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var entries: []
    property string lastContent: ""
    property bool loaded: false

    Component.onCompleted: seedClipboard()

    property Timer pollTimer: Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: checkProc.running = true
    }

    property string pendingOutput: ""

    property Process checkProc: Process {
        command: ["wl-paste", "--no-newline", "-t", "text/plain"]
        running: false
        stdout: SplitParser {
            onRead: data => { pendingOutput += data }
        }
        onExited: (code) => {
            const trimmed = pendingOutput.trim()
            pendingOutput = ""
            if (code === 0 && trimmed.length > 0 && trimmed !== root.lastContent) {
                root.lastContent = trimmed
                root.addEntry(trimmed)
            }
        }
    }

    function seedClipboard() {
        checkSeedProc.running = true
    }

    property Process checkSeedProc: Process {
        command: ["wl-paste", "--no-newline", "-t", "text/plain"]
        running: false
        stdout: SplitParser {
            onRead: data => { pendingOutput += data }
        }
        onExited: (code) => {
            const trimmed = pendingOutput.trim()
            pendingOutput = ""
            if (code === 0 && trimmed.length > 0) {
                root.lastContent = trimmed
                root.addEntry(trimmed)
            }
            root.loaded = true
        }
    }

    function addEntry(text) {
        if (entries.length > 0 && entries[0].text === text) return

        const preview = text.length > 120 ? text.substring(0, 120) + "..." : text
        const entry = { text: text, preview: preview, time: Date.now(), isImage: false }

        const filtered = entries.filter(e => e.text !== text)
        filtered.unshift(entry)
        entries = filtered.slice(0, 80)
    }

    function copyToClipboard(text) {
        lastContent = text
        Qt.callLater(() => {
            copyProc.command = ["bash", "-c", "printf %s " + shellQuote(text) + " | wl-copy"]
            copyProc.running = true
        })
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'"
    }

    property Process copyProc: Process {
        command: ["true"]
        running: false
    }

    function removeEntry(index) {
        const filtered = entries.filter((_, i) => i !== index)
        entries = filtered
    }

    function clearAll() {
        entries = []
    }
}
