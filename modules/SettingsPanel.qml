import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "." as Modules

Rectangle {
    id: panel

    property bool expanded: false
    property string currentPage: "calendar"

    property int panelWidth: 600
    property int panelHeight: 400

    // YT / clock settings persistence — stored alongside the shell so the
    // consumers (YoutubeView, DynamicIsland) read the same files.
    readonly property string configDir: Quickshell.env("HOME") + "/.config/Aki-Shell"
    readonly property string ytSettingsPath: configDir + "/yt-settings.json"
    readonly property string clockSettingsPath: configDir + "/clock-settings.json"
    property string ytChannelId: ""
    property string ytApiKey: ""
    property int ytSubGoal: 2000

    // Clock settings: "24h", "12h", "12h-ampm"
    property string clockFormat: "12h"
    property bool clockShowSeconds: false

    // Shortcut manager
    readonly property string shellkeysPath: Quickshell.env("HOME") + "/.config/hypr/shellkeys.lua"
    property var shortcuts: []
    property bool shortcutSaveFlash: false

    function _loadShortcuts() { shortcutsLoadProc.running = true }
    function _saveShortcuts() {
        var lines = ["local mainMod = \"SUPER\"", ""]
        for (var i = 0; i < shortcuts.length; i++) {
            var s = shortcuts[i]
            var keyPart = s.key.trim()
            if (!keyPart.startsWith("+")) keyPart = " + " + keyPart
            lines.push("hl.bind(mainMod .. \"" + keyPart + "\", hl.dsp.exec_cmd(\"" + s.command + "\"))")
        }
        lines.push("")
        var content = lines.join("\n")
        shortcutsSaveProc.command = ["sh", "-c",
            "mkdir -p '" + shellkeysPath.substring(0, shellkeysPath.lastIndexOf("/")) + "' && " +
            "cat > '" + shellkeysPath + "' << 'ENDOFSHELLKEYS'\n" + content + "\nENDOFSHELLKEYS"]
        shortcutsSaveProc.running = true
        shortcutSaveFlash = true
        shortcutSaveTimer.restart()
    }

    Timer {
        id: shortcutSaveTimer
        interval: 1200
        onTriggered: shortcutSaveFlash = false
    }

    Process {
        id: shortcutsLoadProc
        command: ["sh", "-c", "cat '" + shellkeysPath + "' 2>/dev/null"]
        property var parsed: []
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (!trimmed.startsWith("hl.bind(")) return
                var m = trimmed.match(/hl\.bind\(mainMod\s*\.\.\s*"([^"]*)".*exec_cmd\("([^"]*)"/)
                if (m) {
                    shortcutsLoadProc.parsed.push({
                        key: m[1].replace(/^\s*\+\s*/, ""),
                        command: m[2]
                    })
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                shortcuts = parsed.slice()
                parsed = []
            }
        }
    }

    property Process shortcutsSaveProc: Process {}

    function open() { expanded = true }
    function close() { expanded = false; currentPage = "calendar" }
    function toggle() { expanded = !expanded }

    property bool ytSaveFlash: false

    function _loadYtSettings() { ytLoadProc.running = true }
    function _saveYtSettings() {
        const payload = JSON.stringify({
            channelId: ytChannelId,
            apiKey: ytApiKey,
            subGoal: ytSubGoal
        })
        ytSaveProc.command = ["sh", "-c",
            "mkdir -p '" + configDir + "' && cat > '" + ytSettingsPath + "' << 'EOF'\n" +
            payload + "\nEOF\n"]
        ytSaveProc.running = true
        ytSaveFlash = true
        ytSaveTimer.restart()
    }

    Timer {
        id: ytSaveTimer
        interval: 1500
        repeat: false
        onTriggered: panel.ytSaveFlash = false
    }

    property Process ytLoadProc: Process {
        command: ["sh", "-c", "cat '" + ytSettingsPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) return
                try {
                    const p = JSON.parse(text)
                    panel.ytChannelId = p.channelId ?? ""
                    panel.ytApiKey = p.apiKey ?? ""
                    panel.ytSubGoal = p.subGoal ?? 2000
                } catch (e) {}
            }
        }
    }

    property Process ytSaveProc: Process {}

    // Clock settings persistence
    function _loadClockSettings() { clockLoadProc.running = true }
    function _saveClockSettings() {
        const payload = JSON.stringify({
            format: clockFormat,
            showSeconds: clockShowSeconds
        })
        clockSaveProc.command = ["sh", "-c",
            "mkdir -p '" + configDir + "' && cat > '" + clockSettingsPath + "' << 'EOF'\n" +
            payload + "\nEOF\n"]
        clockSaveProc.running = true
    }

    property Process clockLoadProc: Process {
        command: ["sh", "-c", "cat '" + clockSettingsPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) return
                try {
                    const p = JSON.parse(text)
                    panel.clockFormat = p.format ?? "12h"
                    panel.clockShowSeconds = p.showSeconds ?? false
                } catch (e) {}
            }
        }
    }

    property Process clockSaveProc: Process {}

    Component.onCompleted: {
        _loadYtSettings()
        _loadClockSettings()
        _loadShortcuts()
    }

    width: panelWidth
    height: panelHeight
    color: "#1a1a1e"
    clip: true
    antialiasing: true
    radius: 18

    opacity: expanded ? 1 : 0
    scale: expanded ? 1 : 0.92

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
    }

    focus: true
    Keys.onEscapePressed: panel.close()

    onExpandedChanged: {
        if (expanded) {
            focusRetry.attempts = 0
            focusRetry.start()
            _loadYtSettings()
            _loadClockSettings()
            _loadShortcuts()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            panel.forceActiveFocus()
            attempts++
            if (panel.activeFocus || attempts > 15) stop()
        }
    }

    property var pages: [
        { id: "calendar",   label: "Calendar",      glyph: "\u{1F4C5}" },
        { id: "youtube",    label: "YT Creator",    glyph: "\u{1F3AC}" },
        { id: "clock",      label: "Clock",         glyph: "\u{23F0}" },
        { id: "theme",      label: "Theme",         glyph: "\u{1F3A8}" },
        { id: "shortcuts",  label: "Shortcuts",     glyph: "\u{1F511}" }
    ]

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.55
        shadowBlur: 0.8
        shadowVerticalOffset: 6
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        // --- Sidebar ---
        Rectangle {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: 170
            color: Qt.rgba(0.06, 0.06, 0.07, 0.65)
            radius: 18
            topLeftRadius: 18
            bottomLeftRadius: 18
            topRightRadius: 0
            bottomRightRadius: 0
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 2

                Text {
                    text: "Settings"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.ExtraBold
                    Layout.leftMargin: 6
                    Layout.topMargin: 4
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: panel.pages

                    Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 8
                        color: panel.currentPage === modelData.id
                            ? Qt.rgba(1, 1, 1, 0.1)
                            : (sidebarHover.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: sidebarRow
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            HoverHandler { id: sidebarHover }

                            Text {
                                text: modelData.glyph
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.label
                                color: panel.currentPage === modelData.id ? "white" : Qt.rgba(1, 1, 1, 0.55)
                                font.pixelSize: 12
                                font.weight: panel.currentPage === modelData.id ? Font.DemiBold : Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.currentPage = modelData.id
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // --- Separator line ---
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // --- Content area ---
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // ==================== Calendar Settings ====================
            Item {
                anchors.fill: parent
                anchors.margins: 24
                visible: panel.currentPage === "calendar"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "Calendar"
                        color: "white"
                        font.pixelSize: 18
                        font.weight: Font.ExtraBold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: calAccountCol.implicitHeight + 28
                        radius: 12
                        color: "#222326"

                        ColumnLayout {
                            id: calAccountCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "Google Account"
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: Modules.GoogleAuth.isSignedIn ? "#81c995" : "#9aa0a6"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: Modules.GoogleAuth.isSignedIn ? "Connected" : "Not connected"
                                        color: "white"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: Modules.GoogleAuth.isSignedIn
                                            ? "Calendar events will sync automatically"
                                            : "Sign in to view your Google Calendar events"
                                        color: Qt.rgba(1, 1, 1, 0.4)
                                        font.pixelSize: 10
                                    }
                                    Text {
                                        visible: Modules.GoogleAuth.isSignedIn && Modules.GoogleAuth.email.length > 0
                                        text: Modules.GoogleAuth.email
                                        color: Qt.rgba(1, 1, 1, 0.3)
                                        font.pixelSize: 10
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: calSyncMouse.containsMouse
                                        ? (Modules.GoogleAuth.isSignedIn ? "#2a4a3a" : Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6))
                                        : (Modules.GoogleAuth.isSignedIn ? "#1e3a29" : Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(5), 0.6))
                                    border.width: 1
                                    border.color: Modules.GoogleAuth.isSignedIn ? "#81c995" : Modules.ThemeService.accentColor
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: Modules.GoogleAuth.syncInProgress
                                                ? "Syncing..."
                                                : (Modules.GoogleAuth.isSignedIn ? "Sync now" : "Sign in with Google")
                                            color: Modules.GoogleAuth.isSignedIn ? "#81c995" : Modules.ThemeService.accentColor
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    MouseArea {
                                        id: calSyncMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !Modules.GoogleAuth.syncInProgress
                                        onClicked: {
                                            if (!Modules.GoogleAuth.isSignedIn) Modules.GoogleAuth.syncNow()
                                            else Modules.CalendarService.fetchCurrentWeek()
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: Modules.GoogleAuth.isSignedIn
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: calLogoutMouse.containsMouse ? "#3a1e1e" : "#2a1a1a"
                                    border.width: 1
                                    border.color: calLogoutMouse.containsMouse ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.1)
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Sign out"
                                        color: calLogoutMouse.containsMouse ? "#ff6b6b" : Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: calLogoutMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Modules.GoogleAuth.signOut()
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ==================== YT Creator Settings ====================
            Item {
                anchors.fill: parent
                anchors.margins: 24
                visible: panel.currentPage === "youtube"

                Flickable {
                    anchors.fill: parent
                    contentHeight: ytContent.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: ytContent
                        width: parent.width
                        spacing: 20

                        Text {
                            text: "YT Creator"
                            color: "white"
                            font.pixelSize: 18
                            font.weight: Font.ExtraBold
                        }

                        // Channel ID section
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ytIdCol.implicitHeight + 28
                            radius: 12
                            color: "#222326"

                            ColumnLayout {
                                id: ytIdCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Channel ID"
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: "Find your channel ID in YouTube Studio > Settings > Channel > Basic info"
                                    color: Qt.rgba(1, 1, 1, 0.35)
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: 10
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1
                                    border.color: ytIdInput.activeFocus ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5) : Qt.rgba(1, 1, 1, 0.08)
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    TextInput {
                                        id: ytIdInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: "white"
                                        font.pixelSize: 12
                                        clip: true
                                        selectByMouse: true
                                        text: panel.ytChannelId
                                        onTextChanged: panel.ytChannelId = text

                                        Text {
                                            visible: parent.text.length === 0
                                            text: "UC..."
                                            color: Qt.rgba(1, 1, 1, 0.35)
                                            font: parent.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }

                        // API Key section
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ytKeyCol.implicitHeight + 28
                            radius: 12
                            color: "#222326"

                            ColumnLayout {
                                id: ytKeyCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "API Key"
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: "1. Go to console.cloud.google.com\n2. Create a project (or use existing)\n3. Enable the YouTube Data API v3\n4. Create credentials > API key"
                                    color: Qt.rgba(1, 1, 1, 0.35)
                                    font.pixelSize: 10
                                    lineHeight: 1.4
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: 10
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1
                                    border.color: ytKeyInput.activeFocus ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5) : Qt.rgba(1, 1, 1, 0.08)
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    TextInput {
                                        id: ytKeyInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: "white"
                                        font.pixelSize: 12
                                        clip: true
                                        selectByMouse: true
                                        text: panel.ytApiKey
                                        onTextChanged: panel.ytApiKey = text

                                        Text {
                                            visible: parent.text.length === 0
                                            text: "AIza..."
                                            color: Qt.rgba(1, 1, 1, 0.35)
                                            font: parent.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }

                        // Subscriber Goal section
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ytGoalCol.implicitHeight + 28
                            radius: 12
                            color: "#222326"

                            ColumnLayout {
                                id: ytGoalCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Subscriber Goal"
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        radius: 10
                                        color: Qt.rgba(1, 1, 1, 0.06)
                                        border.width: 1
                                        border.color: ytGoalInput.activeFocus ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5) : Qt.rgba(1, 1, 1, 0.08)
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        TextInput {
                                            id: ytGoalInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: "white"
                                            font.pixelSize: 12
                                            clip: true
                                            selectByMouse: true
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            text: panel.ytSubGoal.toString()
                                            onTextChanged: {
                                                const v = parseInt(text)
                                                if (!isNaN(v) && v > 0) panel.ytSubGoal = v
                                            }

                                            Text {
                                                visible: parent.text.length === 0
                                                text: "2000"
                                                color: Qt.rgba(1, 1, 1, 0.35)
                                                font: parent.font
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    Text {
                                        text: "subscribers"
                                        color: Qt.rgba(1, 1, 1, 0.4)
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }

                        // Save button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 10
                            color: panel.ytSaveFlash ? "#1e3a29"
                                : (ytSaveMouse.containsMouse ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(2), 0.7) : Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6))
                            border.width: 1
                            border.color: panel.ytSaveFlash ? "#81c995" : Modules.ThemeService.accentColor
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: panel.ytSaveFlash ? "Saved!" : "Save"
                                color: panel.ytSaveFlash ? "#81c995" : Modules.ThemeService.accentColor
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: ytSaveMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !panel.ytSaveFlash
                                onClicked: panel._saveYtSettings()
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ==================== Clock Settings ====================
            Item {
                anchors.fill: parent
                anchors.margins: 24
                visible: panel.currentPage === "clock"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "Clock"
                        color: "white"
                        font.pixelSize: 18
                        font.weight: Font.ExtraBold
                    }

                    // Time Format section
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: clockFmtCol.implicitHeight + 28
                        radius: 12
                        color: "#222326"

                        ColumnLayout {
                            id: clockFmtCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "Time Format"
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            // 24h / 12h toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: 8
                                    color: panel.clockFormat === "24h" ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6) : Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1
                                    border.color: panel.clockFormat === "24h" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.08)
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "24h"
                                        color: panel.clockFormat === "24h" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { panel.clockFormat = "24h"; panel._saveClockSettings() }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: 8
                                    color: panel.clockFormat !== "24h" ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6) : Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1
                                    border.color: panel.clockFormat !== "24h" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.08)
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "12h"
                                        color: panel.clockFormat !== "24h" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (panel.clockFormat === "24h") {
                                                panel.clockFormat = "12h"
                                                panel._saveClockSettings()
                                            }
                                        }
                                    }
                                }
                            }

                            // AM/PM sub-options (only when 12h is selected)
                            RowLayout {
                                visible: panel.clockFormat !== "24h"
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: panel.clockFormat === "12h-ampm" ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6) : Qt.rgba(1, 1, 1, 0.04)
                                    border.width: 1
                                    border.color: panel.clockFormat === "12h-ampm" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.06)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "With AM/PM"
                                        color: panel.clockFormat === "12h-ampm" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.45)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { panel.clockFormat = "12h-ampm"; panel._saveClockSettings() }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: panel.clockFormat === "12h" ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6) : Qt.rgba(1, 1, 1, 0.04)
                                    border.width: 1
                                    border.color: panel.clockFormat === "12h" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.06)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Without AM/PM"
                                        color: panel.clockFormat === "12h" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.45)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { panel.clockFormat = "12h"; panel._saveClockSettings() }
                                    }
                                }
                            }
                        }
                    }

                    // Show Seconds toggle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: secRow.implicitHeight + 28
                        radius: 12
                        color: "#222326"

                        RowLayout {
                            id: secRow
                            anchors.fill: parent
                            anchors.margins: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Show Seconds"
                                    color: "white"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "Display seconds in the pill clock"
                                    color: Qt.rgba(1, 1, 1, 0.4)
                                    font.pixelSize: 10
                                }
                            }

                            // Toggle switch
                            Rectangle {
                                width: 40; height: 22; radius: 11
                                color: panel.clockShowSeconds ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: "white"
                                    x: panel.clockShowSeconds ? 20 : 2
                                    y: 2
                                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        panel.clockShowSeconds = !panel.clockShowSeconds
                                        panel._saveClockSettings()
                                    }
                                }
                            }
                        }
                    }

                    // Preview
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        radius: 12
                        color: "#222326"

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Preview"
                                color: Qt.rgba(1, 1, 1, 0.35)
                                font.pixelSize: 10
                            }
                            Text {
                                id: clockPreview
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "white"
                                font.pixelSize: 22
                                font.weight: Font.ExtraBold
                            }
                        }

                        Timer {
                            interval: 500
                            running: panel.currentPage === "clock"
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: {
                                var d = new Date()
                                var h, m, s, suffix = ""
                                if (panel.clockFormat === "24h") {
                                    h = d.getHours()
                                    m = d.getMinutes()
                                    s = d.getSeconds()
                                } else {
                                    h = d.getHours() % 12
                                    if (h === 0) h = 12
                                    m = d.getMinutes()
                                    s = d.getSeconds()
                                    if (panel.clockFormat === "12h-ampm") {
                                        suffix = d.getHours() >= 12 ? " PM" : " AM"
                                    }
                                }
                                var str = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
                                if (panel.clockShowSeconds) str += ":" + (s < 10 ? "0" : "") + s
                                str += suffix
                                clockPreview.text = str
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ==================== Theme Settings ====================
            Item {
                anchors.fill: parent
                anchors.margins: 24
                visible: panel.currentPage === "theme"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    Text {
                        text: "Theme"
                        color: "white"
                        font.pixelSize: 18
                        font.weight: Font.ExtraBold
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: themeContent.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: themeContent
                            width: parent.width
                            spacing: 16

                            // Sync with wallpaper toggle
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: syncRow.implicitHeight + 28
                                radius: 12
                                color: "#222326"

                                RowLayout {
                                    id: syncRow
                                    anchors.fill: parent
                                    anchors.margins: 14

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "Sync with Wallpaper"
                                            color: "white"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                        Text {
                                            text: "Automatically extract accent color from your wallpaper"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        width: 40; height: 22; radius: 11
                                        color: Modules.ThemeService.syncWithWallpaper ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.15)
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Rectangle {
                                            width: 18; height: 18; radius: 9
                                            color: "white"
                                            x: Modules.ThemeService.syncWithWallpaper ? 20 : 2
                                            y: 2
                                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Modules.ThemeService.setSyncWithWallpaper(!Modules.ThemeService.syncWithWallpaper)
                                        }
                                    }
                                }
                            }

                            // Color picker section
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: pickerCol.implicitHeight + 28
                                radius: 12
                                color: "#222326"
                                visible: !Modules.ThemeService.syncWithWallpaper

                                ColumnLayout {
                                    id: pickerCol
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    Text {
                                        text: "Accent Color"
                                        color: Qt.rgba(1, 1, 1, 0.5)
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }

                                    // Current color preview + hex input
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Rectangle {
                                            width: 36; height: 36; radius: 10
                                            color: Modules.ThemeService.accentColor
                                            border.width: 2
                                            border.color: Qt.rgba(1, 1, 1, 0.2)
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            radius: 10
                                            color: Qt.rgba(1, 1, 1, 0.06)
                                            border.width: 1
                                            border.color: hexInput.activeFocus ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5) : Qt.rgba(1, 1, 1, 0.08)

                                            property bool hexInternalChange: false

                                            TextInput {
                                                id: hexInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: "white"
                                                font.pixelSize: 13
                                                font.family: "monospace"
                                                clip: true
                                                selectByMouse: true
                                                text: Modules.ThemeService.accentHex
                                                onTextChanged: {
                                                    if (!parent.hexInternalChange && /^#[0-9a-fA-F]{6}$/.test(text)) {
                                                        parent.hexInternalChange = true
                                                        Modules.ThemeService.setColor(text)
                                                        parent.hexInternalChange = false
                                                    }
                                                }
                                                inputMethodHints: Qt.ImhNoAutoUppercase

                                                Text {
                                                    visible: parent.text.length === 0
                                                    text: "#8ab4f8"
                                                    color: Qt.rgba(1, 1, 1, 0.35)
                                                    font: parent.font
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }

                                    // Hue slider
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: "Hue"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.pixelSize: 10
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 20
                                            radius: 10
                                            clip: true

                                            Canvas {
                                                id: hueCanvas
                                                anchors.fill: parent

                                                property real hue: 0

                                                function hslToHex(h, s, l) {
                                                    function hue2rgb(p, q, t) {
                                                        if (t < 0) t += 1;
                                                        if (t > 1) t -= 1;
                                                        if (t < 1/6) return p + (q - p) * 6 * t;
                                                        if (t < 1/2) return q;
                                                        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                                                        return p;
                                                    }
                                                    var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
                                                    var p = 2 * l - q;
                                                    var r = Math.round(hue2rgb(p, q, h + 1/3) * 255);
                                                    var g = Math.round(hue2rgb(p, q, h) * 255);
                                                    var b = Math.round(hue2rgb(p, q, h - 1/3) * 255);
                                                    return "#" + r.toString(16).padStart(2, "0") +
                                                               g.toString(16).padStart(2, "0") +
                                                               b.toString(16).padStart(2, "0");
                                                }

                                                onPaint: {
                                                    var ctx = getContext("2d")
                                                    var w = width
                                                    var grad = ctx.createLinearGradient(0, 0, w, 0)
                                                    for (var i = 0; i <= 360; i += 30) {
                                                        grad.addColorStop(i / 360, hslToHex(i / 360, 1, 0.5))
                                                    }
                                                    ctx.fillStyle = grad
                                                    ctx.beginPath()
                                                    ctx.roundedRect(0, 0, w, height, 10, 10)
                                                    ctx.fill()
                                                }

                                                Component.onCompleted: requestPaint()

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onPositionChanged: (mouse) => {
                                                        var ratio = Math.max(0, Math.min(1, mouse.x / hueCanvas.width))
                                                        hueCanvas.hue = ratio
                                                        Modules.ThemeService.setColor(hueCanvas.hslToHex(ratio, 1, 0.5))
                                                    }
                                                    onClicked: (mouse) => {
                                                        var ratio = Math.max(0, Math.min(1, mouse.x / hueCanvas.width))
                                                        hueCanvas.hue = ratio
                                                        Modules.ThemeService.setColor(hueCanvas.hslToHex(ratio, 1, 0.5))
                                                    }
                                                }

                                                // Indicator
                                                Rectangle {
                                                    x: hueCanvas.hue * hueCanvas.width - 6
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 12; height: 12; radius: 6
                                                    color: hueCanvas.hslToHex(hueCanvas.hue, 1, 0.5)
                                                    border.width: 2
                                                    border.color: "white"
                                                }
                                            }
                                        }
                                    }

                                    // Preset swatches
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "Presets"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.pixelSize: 10
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Repeater {
                                                    model: [
                                                    Modules.ThemeService.accentHex, "#7c9bff", "#a78bfa", "#c084fc",
                                                    "#f472b6", "#fb7185", "#f87171", "#fb923c",
                                                    "#fbbf24", "#a3e635", "#4ade80", "#34d399",
                                                    "#22d3ee", "#38bdf8", "#60a5fa", "#818cf8"
                                                ]

                                                Rectangle {
                                                    required property string modelData
                                                    width: 32; height: 32; radius: 8
                                                    color: modelData
                                                    border.width: Modules.ThemeService.accentHex === modelData ? 2 : 0
                                                    border.color: "white"
                                                    opacity: swatchMouse.containsMouse ? 1 : 0.85

                                                    Behavior on opacity { NumberAnimation { duration: 80 } }

                                                    MouseArea {
                                                        id: swatchMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Modules.ThemeService.setColor(parent.modelData)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==================== Shortcut Manager ====================
            Item {
                anchors.fill: parent
                anchors.margins: 24
                visible: panel.currentPage === "shortcuts"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Shortcuts"
                            color: "white"
                            font.pixelSize: 18
                            font.weight: Font.ExtraBold
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: panel.shortcutSaveFlash
                            text: "Saved! Restart hyprland to apply"
                            color: "#81c995"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            opacity: panel.shortcutSaveFlash ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Rectangle {
                            Layout.preferredWidth: saveBtnShortcuts.implicitWidth + 24
                            Layout.preferredHeight: 30
                            radius: 8
                            color: panel.shortcutSaveFlash ? "#1e3a29"
                                : (shortcutsSaveMouse.containsMouse
                                    ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(2), 0.7)
                                    : Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentDimmed(3), 0.6))
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: saveBtnShortcuts
                                anchors.centerIn: parent
                                text: panel.shortcutSaveFlash ? "Saved!" : "Save"
                                color: panel.shortcutSaveFlash ? "#81c995" : Modules.ThemeService.accentColor
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: shortcutsSaveMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panel._saveShortcuts()
                            }
                        }
                    }

                    Text {
                        text: "Edit keybindings below. Changes apply after restarting Hyprland."
                        color: Qt.rgba(1, 1, 1, 0.35)
                        font.pixelSize: 10
                        Layout.bottomMargin: 4
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: shortcutsCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: shortcutsCol
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: panel.shortcuts.length

                                Rectangle {
                                    required property int index
                                    property var shortcut: panel.shortcuts[index]

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    radius: 8
                                    color: shortcutRow.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    HoverHandler { id: shortcutRow }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        // Command label
                                        Text {
                                            text: {
                                                var cmd = shortcut.command
                                                if (cmd.indexOf("toggleClipboard") >= 0) return "Clipboard"
                                                if (cmd.indexOf("toggleMovies") >= 0) return "Movies"
                                                if (cmd.indexOf("toggleYoutube") >= 0) return "YouTube"
                                                if (cmd.indexOf("call power") >= 0) return "Power Menu"
                                                if (cmd.indexOf("call audio") >= 0) return "Audio"
                                                if (cmd.indexOf("call network") >= 0) return "Network"
                                                if (cmd.indexOf("call music") >= 0) return "Music"
                                                if (cmd.indexOf("call wallpaper") >= 0) return "Wallpaper"
                                                if (cmd.indexOf("call settings") >= 0) return "Settings"
                                                if (cmd.indexOf("call island") >= 0) return "Island"
                                                return cmd
                                            }
                                            color: Qt.rgba(1, 1, 1, 0.7)
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Key binding display
                                        Rectangle {
                                            Layout.preferredWidth: keyLabel.implicitWidth + 16
                                            Layout.preferredHeight: 28
                                            radius: 6
                                            color: keyMouse.containsMouse
                                                ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.12)
                                                : Qt.rgba(1, 1, 1, 0.06)
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.1)

                                            Text {
                                                id: keyLabel
                                                anchors.centerIn: parent
                                                text: "SUPER + " + shortcut.key
                                                color: "white"
                                                font.pixelSize: 11
                                                font.family: "monospace"
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                id: keyMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    keyEditOverlay.shortcutIndex = index
                                                    keyEditOverlay.currentKey = shortcut.key
                                                    keyEditOverlay.visible = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }

            // Key edit overlay
            FocusScope {
                id: keyEditOverlay
                visible: false
                anchors.centerIn: parent
                width: 320
                height: 160
                z: 100

                property int shortcutIndex: -1
                property string currentKey: ""
                property string capturedKey: ""

                onVisibleChanged: {
                    if (visible) {
                        capturedKey = currentKey
                        forceActiveFocus()
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        visible = false
                        return
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (capturedKey.length > 0) acceptEdit()
                        return
                    }
                    // Build key name from modifiers + key
                    var parts = []
                    if (event.modifiers & Qt.AltModifier) parts.push("ALT")
                    if (event.modifiers & Qt.ControlModifier) parts.push("CTRL")
                    if (event.modifiers & Qt.ShiftModifier) parts.push("SHIFT")
                    var keyName = keyNameFromEvent(event.key)
                    if (keyName.length > 0) parts.push(keyName)
                    capturedKey = parts.join(" + ")
                }

                function keyNameFromEvent(k) {
                    if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
                    if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
                    if (k === Qt.Key_Space) return "SPACE"
                    if (k === Qt.Key_Escape) return ""
                    if (k === Qt.Key_Return || k === Qt.Key_Enter) return ""
                    if (k === Qt.Key_Tab) return "TAB"
                    if (k === Qt.Key_Backspace) return ""
                    if (k === Qt.Key_Delete) return ""
                    if (k === Qt.Key_Up) return "UP"
                    if (k === Qt.Key_Down) return "DOWN"
                    if (k === Qt.Key_Left) return "LEFT"
                    if (k === Qt.Key_Right) return "RIGHT"
                    if (k === Qt.Key_F1) return "F1"
                    if (k === Qt.Key_F2) return "F2"
                    if (k === Qt.Key_F3) return "F3"
                    if (k === Qt.Key_F4) return "F4"
                    if (k === Qt.Key_F5) return "F5"
                    if (k === Qt.Key_F6) return "F6"
                    if (k === Qt.Key_F7) return "F7"
                    if (k === Qt.Key_F8) return "F8"
                    if (k === Qt.Key_F9) return "F9"
                    if (k === Qt.Key_F10) return "F10"
                    if (k === Qt.Key_F11) return "F11"
                    if (k === Qt.Key_F12) return "F12"
                    if (k === Qt.Key_Minus) return "MINUS"
                    if (k === Qt.Key_Equal) return "EQUAL"
                    if (k === Qt.Key_BracketLeft) return "BRACKETLEFT"
                    if (k === Qt.Key_BracketRight) return "BRACKETRIGHT"
                    if (k === Qt.Key_Backslash) return "BACKSLASH"
                    if (k === Qt.Key_Semicolon) return "SEMICOLON"
                    if (k === Qt.Key_Apostrophe) return "APOSTROPHE"
                    if (k === Qt.Key_Grave) return "GRAVE"
                    if (k === Qt.Key_Comma) return "COMMA"
                    if (k === Qt.Key_Period) return "PERIOD"
                    if (k === Qt.Key_Slash) return "SLASH"
                    return ""
                }

                function acceptEdit() {
                    var newKey = capturedKey.trim()
                    if (newKey.length === 0) return
                    var arr = shortcuts
                    arr[shortcutIndex] = { key: newKey, command: arr[shortcutIndex].command }
                    shortcuts = arr
                    visible = false
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: "#222326"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    MouseArea { anchors.fill: parent }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Text {
                            text: "Edit Keybinding"
                            color: "white"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Press the new key combination"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 10
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "SUPER +"
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.pixelSize: 12
                                font.family: "monospace"
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: 8
                                color: keyEditOverlay.activeFocus
                                    ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.08)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                border.color: keyEditOverlay.activeFocus
                                    ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5)
                                    : Qt.rgba(1, 1, 1, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: keyEditOverlay.capturedKey.length > 0
                                        ? keyEditOverlay.capturedKey
                                        : "Press keys..."
                                    color: keyEditOverlay.capturedKey.length > 0 ? "white" : Qt.rgba(1, 1, 1, 0.25)
                                    font.pixelSize: 13
                                    font.family: "monospace"
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 28
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: keyEditOverlay.visible = false
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 28
                                radius: 6
                                color: keyEditOverlay.capturedKey.length > 0
                                    ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.15)
                                    : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: "OK"
                                    color: keyEditOverlay.capturedKey.length > 0
                                        ? Modules.ThemeService.accentColor
                                        : Qt.rgba(1, 1, 1, 0.25)
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: keyEditOverlay.capturedKey.length > 0
                                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: keyEditOverlay.acceptEdit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
