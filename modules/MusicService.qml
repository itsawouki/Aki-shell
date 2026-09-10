pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: service

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/play_music.sh"

    property var playlists: []
    property string currentPlaylist: ""
    property bool isPlaying: false

    Component.onCompleted: refresh()

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    function play(name) {
        if (!name) return

        playProc.command = [scriptPath, "--play", name]
        playProc.running = false
        playProc.running = true

        service.currentPlaylist = name
        service.isPlaying = true
    }

    function stop() {
        stopProc.running = false
        stopProc.running = true

        service.currentPlaylist = ""
        service.isPlaying = false
    }

    function togglePlay(name) {
        if (service.currentPlaylist === name && service.isPlaying) {
            stop()
        } else {
            play(name)
        }
    }

    Process {
        id: playProc
        running: false
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.log("PlayProc Error: " + text)
        }
    }

    Process {
        id: stopProc
        command: [scriptPath, "--stop"]
        running: false
    }

    Process {
        id: listProc
        command: [scriptPath, "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                service.playlists = lines.map(line => {
                    const parts = line.split("\t")
                    if (parts[1] === "yt") {
                        return { name: parts[0], isYt: true, url: parts[2] || "" }
                    }
                    return { name: parts[0], isYt: false, url: "" }
                })
            }
        }
    }
}
