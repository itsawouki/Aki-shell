import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "." as Modules

Rectangle {
    id: island

    // --- Position & Anchoring ---
    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    // --- State Flags ---
    property bool expanded: false          // App launcher
    property bool musicOpen: false         // Music player
    property bool powerOpen: false         // Power options
    property bool wallpaperOpen: false     // Wallpaper picker
    property bool calendarOpen: false      // Calendar & week tasks view
    property bool movieOpen: false         // Movies & shows picker
    property bool youtubeOpen: false       // YouTube tracker view
    property bool clipboardOpen: false     // Clipboard history
    property bool showingWorkspace: false  // Workspace indicator
    property string recordingState: "off"  // "recording", "paused", or "off"

    readonly property bool anyOpen: expanded || musicOpen || powerOpen || wallpaperOpen || calendarOpen || movieOpen || youtubeOpen || clipboardOpen

    // --- Focus & Click Dismiss Logic ---
    focus: true

    onAnyOpenChanged: {
        if (anyOpen) {
            island.forceActiveFocus()
        }
    }

    // --- Background Screen Recording Detector ---
    Process {
        id: checkRecorder
        command: [
            "bash", "-c",
            "PIDS=$(pgrep -f '[o]bs'); " +
            "if [ -n \"$PIDS\" ]; then " +
            "  for pid in $PIDS; do " +
            "    for fd in /proc/$pid/fd/*; do " +
            "      target=$(readlink -f \"$fd\" 2>/dev/null); " +
            "      if echo \"$target\" | grep -qiE '\\.(mkv|mp4|webm|mov|flv|ts|m2ts)$'; then " +
            "        mtime=$(stat -c %Y \"$target\" 2>/dev/null || echo 0); " +
            "        now=$(date +%s); " +
            "        if [ $(( now - mtime )) -le 5 ]; then exit 0; else exit 2; fi; " +
            "      fi; " +
            "    done; " +
            "  done; " +
            "fi; " +
            "if pgrep -f '[w]f-recorder|[w]l-screenrec|[g]pu-screen-recorder' >/dev/null 2>&1; then exit 0; fi; " +
            "exit 1"
        ]
        running: false
        onExited: (code) => {
            if (code === 0) island.recordingState = "recording"
            else if (code === 2) island.recordingState = "paused"
            else island.recordingState = "off"
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkRecorder.running) checkRecorder.running = true
        }
    }

    // --- Hyprland Workspace Tracking ---
    readonly property int activeWsId: Hyprland.focusedWorkspace?.id ?? 1
    property bool isInitialized: false

    onActiveWsIdChanged: {
        if (!isInitialized) {
            isInitialized = true
            return
        }

        if (!anyOpen) {
            showingWorkspace = true
            wsTimer.restart()
        }
    }

    Timer {
        id: wsTimer
        interval: 1500
        repeat: false
        onTriggered: island.showingWorkspace = false
    }

    // --- View Dimensions ---
    property int collapsedWidth: 150
    property int collapsedHeight: 32

    property int expandedWidth: 560
    property int expandedHeight: 440

    property int musicWidth: 340
    property int musicHeight: 380

    property int powerWidth: 320
    property int powerHeight: 96

    property int wallpaperWidth: 540
    property int wallpaperHeight: 114

    property int calendarWidth: 520
    property int calendarHeight: 280

    property int movieWidth: 460
    property int movieHeight: 420

    property int youtubeWidth: 430
    property int youtubeHeight: 120

    property int clipboardWidth: 460
    property int clipboardHeight: 420

    property int workspaceWidth: 200
    property int workspaceHeight: 38

    property int recordingWidth: 180
    property int recordingHeight: 36

    property int focusWidth: 160
    property int focusHeight: 34

    property bool hovered: false
    property int mediaWidth: 400
    property int mediaHeight: 120

    property int notifWidth: 360
    property int notifHeight: 84
    property int notifDurationMs: 4000

    // --- Active View Calculations ---
    // Strict priority order, each level may only depend on higher ones:
    // open views > workspace flash > notification > hover media > recording.
    // Hover deliberately outranks the recording indicator so the media
    // viewer stays usable while a screen recording is active.
    readonly property var currentNotification: Modules.NotificationQueue.current
    property bool showingMedia: hovered && !anyOpen && !showingWorkspace && currentNotification === null
    readonly property bool showingNotification: !anyOpen && !showingWorkspace && !showingMedia && currentNotification !== null
    readonly property bool showingRecording: !anyOpen && !showingWorkspace && !showingMedia && !showingNotification && recordingState !== "off"
    readonly property bool showingFocusTimer: !anyOpen && !showingWorkspace && !showingRecording && !showingNotification && !showingMedia && Modules.FocusManager.running

    // --- State Control Functions ---
    function open() {
        closeAll()
        expanded = true
    }

    function closeAll() {
        expanded = false
        musicOpen = false
        powerOpen = false
        wallpaperOpen = false
        calendarOpen = false
        movieOpen = false
        youtubeOpen = false
        clipboardOpen = false
        showingWorkspace = false
        if (launcherView) launcherView.reset()
    }

    function toggle(targetView) {
        if (!targetView || targetView === "launcher" || targetView === "apps") {
            if (expanded) closeAll()
            else open()
        } else if (targetView === "calendar") {
            toggleCalendar()
        } else if (targetView === "music") {
            toggleMusic()
        } else if (targetView === "power") {
            togglePower()
        } else if (targetView === "wallpaper") {
            toggleWallpaper()
        } else if (targetView === "movies") {
            toggleMovies()
        } else if (targetView === "youtube") {
            toggleYoutube()
        } else if (targetView === "clipboard") {
            toggleClipboard()
        } else {
            if (anyOpen) closeAll()
            else open()
        }
    }

    function toggleCalendar() {
        if (calendarOpen) closeAll()
        else { closeAll(); calendarOpen = true }
    }

    function toggleMusic() {
        if (musicOpen) closeAll()
        else { closeAll(); musicOpen = true }
    }

    function togglePower() {
        if (powerOpen) closeAll()
        else { closeAll(); powerOpen = true }
    }

    function toggleWallpaper() {
        if (wallpaperOpen) closeAll()
        else { closeAll(); wallpaperOpen = true }
    }

    function openMovies() {
        closeAll()
        movieOpen = true
    }

    function closeMovies() {
        movieOpen = false
    }

    function toggleMovies() {
        if (movieOpen) closeAll()
        else { closeAll(); movieOpen = true }
    }

    function toggleYoutube() {
        if (youtubeOpen) closeAll()
        else { closeAll(); youtubeOpen = true }
    }

    function toggleClipboard() {
        if (clipboardOpen) closeAll()
        else { closeAll(); clipboardOpen = true }
    }

    function currentWidth() {
        if (expanded) return expandedWidth
        if (musicOpen) return musicWidth
        if (powerOpen) return powerWidth
        if (wallpaperOpen) return wallpaperWidth
        if (calendarOpen) return calendarWidth
        if (movieOpen) return movieWidth
        if (youtubeOpen) return youtubeWidth
        if (clipboardOpen) return clipboardWidth
        if (showingWorkspace) return workspaceWidth
        if (showingRecording) return recordingWidth
        if (showingNotification) return notifWidth
        if (showingMedia) return mediaWidth
        if (showingFocusTimer) return focusWidth
        return collapsedWidth
    }

    function currentHeight() {
        if (expanded) return expandedHeight
        if (musicOpen) return musicHeight
        if (powerOpen) return powerHeight
        if (wallpaperOpen) return wallpaperHeight
        if (calendarOpen) return calendarHeight
        if (movieOpen) return movieHeight
        if (youtubeOpen) return youtubeHeight
        if (clipboardOpen) return clipboardHeight
        if (showingWorkspace) return workspaceHeight
        if (showingRecording) return recordingHeight
        if (showingNotification) return notifHeight
        if (showingMedia) return mediaHeight
        if (showingFocusTimer) return focusHeight
        return collapsedHeight
    }

    // --- Container Styling ---
    width: currentWidth()
    height: currentHeight()
    color: "#141416"
    clip: true
    antialiasing: true
    radius: anyOpen ? 22 : (showingMedia || showingNotification || showingWorkspace || showingRecording || showingFocusTimer ? 18 : 14)
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: radius
    bottomRightRadius: radius

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.6
        shadowBlur: 1
        shadowVerticalOffset: 4
    }

    Behavior on width {
        NumberAnimation { duration: 240; easing.type: Easing.OutExpo }
    }
    Behavior on height {
        NumberAnimation { duration: 240; easing.type: Easing.OutExpo }
    }
    Behavior on radius {
        NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
    }

    // --- Clock Settings ---
    readonly property string clockSettingsPath: Quickshell.env("HOME") + "/.config/Aki-Shell/clock-settings.json"
    property string clockFormat: "12h"
    property bool clockShowSeconds: false

    Process {
        id: clockSettingsLoad
        command: ["sh", "-c", "cat '" + island.clockSettingsPath + "' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const p = JSON.parse(data)
                    island.clockFormat = p.format ?? "12h"
                    island.clockShowSeconds = p.showSeconds ?? false
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!clockSettingsLoad.running) clockSettingsLoad.running = true
    }

    // --- Clock (Collapsed Display) ---
    Text {
        id: clockText
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 15
        font.weight: Font.ExtraBold
        opacity: (anyOpen || showingWorkspace || showingRecording || island.showingMedia || island.showingNotification || island.showingFocusTimer) ? 0 : 1
        scale: opacity > 0 ? 1 : 0.8
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutExpo }
        }

        Timer {
            interval: island.clockShowSeconds ? 500 : 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var d = new Date()
                var h, m, s, suffix = ""
                if (island.clockFormat === "24h") {
                    h = d.getHours()
                    m = d.getMinutes()
                    s = d.getSeconds()
                } else {
                    h = d.getHours() % 12
                    if (h === 0) h = 12
                    m = d.getMinutes()
                    s = d.getSeconds()
                    if (island.clockFormat === "12h-ampm") {
                        suffix = d.getHours() >= 12 ? " PM" : " AM"
                    }
                }
                var str = h + ":" + (m < 10 ? "0" : "") + m
                if (island.clockShowSeconds) str += ":" + (s < 10 ? "0" : "") + s
                str += suffix
                clockText.text = str
            }
        }
    }

    // --- Active Focus Timer Notch Readout ---
    Row {
        id: focusTimerRow
        anchors.centerIn: parent
        spacing: 8
        opacity: island.showingFocusTimer && !island.showingMedia ? 1 : 0
        scale: opacity > 0 ? 1 : 0.8
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutExpo }
        }

        Text {
            text: "🎯"
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Modules.FocusManager.formattedTime
            color: "#a855f7"
            font.pixelSize: 13
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: island.hovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: !anyOpen && !showingWorkspace
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                island.toggleCalendar()
            } else if (island.showingNotification) {
                Modules.NotificationQueue.activateCurrent()
            } else {
                island.open()
            }
        }
    }

    // --- Sub-View Modules ---

    // 1. Screen Recording Indicator
    Modules.RecordingView {
        id: recordingViewItem
        anchors.fill: parent
        opacity: island.showingRecording ? 1 : 0
        visible: opacity > 0.01
        status: island.recordingState
        Behavior on opacity {
            NumberAnimation { duration: island.showingRecording ? 180 : 100; easing.type: Easing.OutCubic }
        }
    }

    // 2. Workspace Indicator
    Modules.WorkspaceView {
        id: workspaceViewItem
        anchors.fill: parent
        activeWs: island.activeWsId
        opacity: island.showingWorkspace ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: island.showingWorkspace ? 180 : 100; easing.type: Easing.OutCubic }
        }
    }

    // 3. Wallpaper Picker
    Modules.WallpaperView {
        id: wallpaperViewItem
        anchors.fill: parent
        anchors.margins: 12
        opacity: wallpaperOpen ? 1 : 0
        visible: opacity > 0.01
        active: wallpaperOpen
        Behavior on opacity {
            NumberAnimation { duration: wallpaperOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 4. Hover Media Player
    Modules.MediaView {
        id: mediaViewItem
        anchors.fill: parent
        anchors.margins: 14
        opacity: island.showingMedia ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: island.showingMedia ? 200 : 100; easing.type: Easing.OutCubic }
        }
    }

    // 5. Notification Popups
    Modules.NotificationView {
        id: notificationViewItem
        anchors.fill: parent
        anchors.margins: 14
        notification: island.currentNotification
        opacity: island.showingNotification ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: island.showingNotification ? 180 : 120; easing.type: Easing.OutCubic }
        }
    }

    Timer {
        id: notifTimer
        interval: island.notifDurationMs
        running: island.showingNotification
        onTriggered: Modules.NotificationQueue.advance()
    }

    Connections {
        target: Modules.NotificationQueue
        function onCurrentChanged() {
            if (Modules.NotificationQueue.current !== null) {
                notifTimer.restart()
            }
        }
    }

    // 6. App Launcher
    Modules.Launcher {
        id: launcherView
        anchors.fill: parent
        anchors.margins: 14
        opacity: expanded ? 1 : 0
        visible: opacity > 0.01
        active: expanded
        Behavior on opacity {
            NumberAnimation { duration: expanded ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 7. Music Selector
    Modules.MusicView {
        id: musicViewItem
        anchors.fill: parent
        anchors.margins: 16
        opacity: musicOpen ? 1 : 0
        visible: opacity > 0.01
        active: musicOpen
        Behavior on opacity {
            NumberAnimation { duration: musicOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 8. Power Menu
    Modules.PowerView {
        id: powerViewItem
        anchors.fill: parent
        anchors.margins: 12
        opacity: powerOpen ? 1 : 0
        visible: opacity > 0.01
        active: powerOpen
        Behavior on opacity {
            NumberAnimation { duration: powerOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 9. Calendar / Week Tasks Notch
    Modules.CalendarView {
        id: calendarViewItem
        anchors.fill: parent
        anchors.margins: 14
        opacity: calendarOpen ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: calendarOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 10. Movies & Shows Picker
    Modules.MovieView {
        id: movieViewItem
        anchors.fill: parent
        anchors.margins: 14
        opacity: movieOpen ? 1 : 0
        visible: opacity > 0.01
        active: movieOpen
        Behavior on opacity {
            NumberAnimation { duration: movieOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 11. YouTube Tracker
    Modules.YoutubeView {
        id: youtubeViewItem
        anchors.fill: parent
        anchors.margins: 14
        opacity: youtubeOpen ? 1 : 0
        visible: opacity > 0.01
        active: youtubeOpen
        Behavior on opacity {
            NumberAnimation { duration: youtubeOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }

    // 12. Clipboard History
    Modules.ClipboardView {
        id: clipboardViewItem
        anchors.fill: parent
        anchors.margins: 14
        opacity: clipboardOpen ? 1 : 0
        visible: opacity > 0.01
        active: clipboardOpen
        Behavior on opacity {
            NumberAnimation { duration: clipboardOpen ? 200 : 100; easing.type: Easing.OutCubic }
        }
        onRequestClose: island.closeAll()
    }
}
