pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/movie_backend.py"

    property var library: []
    property bool loading: false
    property string lastError: ""

    function refresh() {
        loading = true
        lastError = ""
        loadProc.command = ["python3", root.scriptPath]
        loadProc.running = true
    }

    Component.onCompleted: refresh()

    property Process loadProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    root.library = JSON.parse(text)
                } catch (e) {
                    root.lastError = "Failed to parse movie library — check movie_backend.py output."
                    console.log("[MovieService] parse error:", e, "raw:", text.slice(0, 200))
                }
            }
        }
    }

    property Timer refreshTimer: Timer {
        interval: 150
        repeat: false
        onTriggered: root.refresh()
    }

    property var _mutationQueue: []
    property bool _mutationRunning: false

    function _runMutation(args) {
        _mutationQueue.push(args)
        _pumpMutations()
    }

    function _pumpMutations() {
        if (_mutationRunning || _mutationQueue.length === 0) return
        const args = _mutationQueue.shift()
        console.log("[MovieService] running:", ["python3", root.scriptPath].concat(args).join(" "))
        mutationProc.command = ["python3", root.scriptPath].concat(args)
        mutationProc.running = true
    }

    property Process mutationProc: Process {
        onExited: {
            root._mutationRunning = false
            if (root._mutationQueue.length === 0) {
                refreshTimer.restart()
            } else {
                root._pumpMutations()
            }
        }
    }

    function removeMovie(movieId) {
        _runMutation(["remove_movie", movieId.toString()])
    }

    function removeEpisode(movieId, epUrl) {
        _runMutation(["remove_episode", movieId.toString(), epUrl])
    }

    function toggleWatched(path) {
        _runMutation(["mark_watched", path])
    }

    function markWatched(path) {
        _runMutation(["set_watched", path])
    }

    function addOnlineMovie(title, url, cover) {
        _runMutation(["add_online_movie", title, url, cover ?? ""])
    }

    function addShow(title, cover) {
        _runMutation(["add_show", title, cover ?? ""])
    }

    function addSeason(title, seasonName) {
        _runMutation(["add_season", title, seasonName])
    }

    function renameSeason(title, oldName, newName) {
        _runMutation(["rename_season", title, oldName, newName])
    }

    function removeSeason(title, seasonName) {
        _runMutation(["remove_season", title, seasonName])
    }

    function addOnlineEpisode(title, epTitle, url, season) {
        var args = ["add_online_episode", title, epTitle, url]
        if (season && season.length > 0) args.push(season)
        _runMutation(args)
    }

    function addOnlineEpisodes(title, season, episodes) {
        _runMutation(["add_online_episodes", title, season ?? "", JSON.stringify(episodes)])
    }

    function setCover(title, coverUrl) {
        _runMutation(["set_cover", title, coverUrl])
    }

    function play(path) {
        Quickshell.execDetached({ command: ["mpv", path] })
    }
}
