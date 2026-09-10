pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Central place for everything audio-related. AudioPanel (the right-side
// notch) reads from this and calls its functions; nothing else needs to
// touch Quickshell.Services.Pipewire directly.
Singleton {
    id: service

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real sinkVolume: sink?.audio?.volume ?? 0
    readonly property bool sinkMuted: sink?.audio?.muted ?? false
    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false

    // Hardware/virtual devices only — isStream true means it's an
    // application's stream, not a physical or virtual output/input.
    readonly property var outputs: Pipewire.nodes.values.filter(function (n) {
        return n.audio && n.type === PwNodeType.AudioSink && !n.isStream
    })
    readonly property var inputs: Pipewire.nodes.values.filter(function (n) {
        return n.audio && n.type === PwNodeType.AudioSource && !n.isStream
    })

    function setSinkVolume(v) {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function toggleSinkMute() {
        if (sink?.ready && sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    function setSourceVolume(v) {
        if (source?.ready && source?.audio) {
            source.audio.muted = false
            source.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function toggleSourceMute() {
        if (source?.ready && source?.audio) source.audio.muted = !source.audio.muted
    }

    function selectOutput(node) { Pipewire.preferredDefaultAudioSink = node }
    function selectInput(node) { Pipewire.preferredDefaultAudioSource = node }

    // --- Notification ducking -------------------------------------------
    // Briefly lowers application playback streams (not the sink itself,
    // so the alert sound stays at full volume) whenever a notification
    // arrives. Tune duckLevel down for stronger ducking.
    property real duckLevel: 0.45
    property int duckHoldMs: 4500
    property var _duckedVolumes: ({})

    function _duckableStreams() {
        return Pipewire.nodes.values.filter(function (n) {
            if (!n.isStream || n.type !== PwNodeType.AudioSink) return false
            if (!n.audio || !n.ready || n.audio.muted) return false
            // Never touch the notification alert player itself.
            const label = ((n.name ?? "") + " " + (n.description ?? "")).toLowerCase()
            return !/paplay|pw-play|canberra/.test(label)
        })
    }

    function duckForNotification() {
        // Already ducked? Just extend the hold — re-snapshotting now would
        // record the lowered volumes and the originals would be lost.
        if (duckTimer.running) {
            duckTimer.restart()
            return
        }
        var snapshot = {}
        const streams = _duckableStreams()
        for (var i = 0; i < streams.length; i++) {
            const s = streams[i]
            snapshot[s.id] = s.audio.volume
            s.audio.volume = Math.max(0, s.audio.volume * duckLevel)
        }
        _duckedVolumes = snapshot
        duckTimer.restart()
    }

    function restoreDuckedVolumes() {
        const nodes = Pipewire.nodes.values
        for (const idStr in _duckedVolumes) {
            const node = nodes.find(n => n.id === Number(idStr))
            if (node?.audio) node.audio.volume = _duckedVolumes[idStr]
        }
        _duckedVolumes = ({})
    }

    Timer {
        id: duckTimer
        interval: service.duckHoldMs
        onTriggered: service.restoreDuckedVolumes()
    }

    // Keeps sink/source/every listed device bound so their properties
    // (volume, muted, ready) actually update reactively.
    PwObjectTracker {
        objects: [service.sink, service.source].concat(service.outputs, service.inputs)
    }
}
