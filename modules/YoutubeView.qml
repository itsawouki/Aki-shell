import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    signal requestClose()

    property bool active: false

    onActiveChanged: {
        if (active) {
            focusRetry.attempts = 0
            focusRetry.start()
            _loadSettings()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            root.forceActiveFocus()
            attempts++
            if (root.activeFocus || attempts > 15) stop()
        }
    }

    Keys.onEscapePressed: root.requestClose()

    // Load settings from yt-settings.json
    readonly property string configDir: Quickshell.env("HOME") + "/.config/Aki-Shell"
    readonly property string ytSettingsPath: configDir + "/yt-settings.json"

    property string channelId: ""
    property string apiKey: ""
    property int subGoal: 2000
    property bool configured: channelId.length > 0 && apiKey.length > 0

    property int rawSubs: 0
    property real progress: Math.min(1.0, Math.max(0.0, rawSubs / subGoal))

    property string subCount: "..."
    property string viewCount: "..."

    Component.onCompleted: _loadSettings()

    function _loadSettings() {
        ytLoadProc.running = true
    }

    property Process ytLoadProc: Process {
        command: ["sh", "-c", "cat '" + root.ytSettingsPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) return
                try {
                    const p = JSON.parse(text)
                    root.channelId = p.channelId ?? ""
                    root.apiKey = p.apiKey ?? ""
                    root.subGoal = p.subGoal ?? 2000
                    if (root.configured) _fetchStats()
                } catch (e) {}
            }
        }
    }

    function _fetchStats() {
        if (!configured || fetchStats.running) return
        fetchStats.running = true
    }

    Process {
        id: fetchStats
        command: [
            "python3", "-c",
            "import urllib.request, json\n" +
            "url = 'https://www.googleapis.com/youtube/v3/channels?part=statistics&id=" + root.channelId + "&key=" + root.apiKey + "'\n" +
            "data = json.loads(urllib.request.urlopen(url).read().decode('utf-8'))\n" +
            "s = data['items'][0]['statistics']\n" +
            "print(f\"{s['subscriberCount']}|{s['viewCount']}\")"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|")
                if (parts.length === 2) {
                    let subs = parseInt(parts[0]) || 0
                    let views = parseInt(parts[1]) || 0
                    root.rawSubs = subs
                    root.subCount = subs.toLocaleString()
                    root.viewCount = views.toLocaleString()
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: root.configured
        repeat: true
        triggeredOnStart: true
        onTriggered: root._fetchStats()
    }

    // Sync prompt when not configured
    Item {
        anchors.centerIn: parent
        visible: !root.configured

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\u{1F3AC}"
                font.pixelSize: 28
                opacity: 0.4
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sync your YT account"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Add your channel ID and API key in Settings"
                color: Qt.rgba(1, 1, 1, 0.3)
                font.pixelSize: 10
            }
        }
    }

    // Stats display when configured
    Row {
        anchors.centerIn: parent
        spacing: 10
        visible: root.configured

        // Card 1: Subscriber Goal Progress
        Rectangle {
            width: 195
            height: 94
            color: "#1a1a1e"
            radius: 18

            Row {
                anchors.centerIn: parent
                spacing: 12

                Canvas {
                    id: subCanvas
                    width: 56
                    height: 56
                    anchors.verticalCenter: parent.verticalCenter

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2
                        var cy = height / 2
                        var r = (width - 8) / 2
                        var start = -Math.PI / 2
                        var end = start + (2 * Math.PI * root.progress)

                        ctx.lineWidth = 5
                        ctx.strokeStyle = "#2a2a32"
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                        ctx.stroke()

                        if (root.progress > 0) {
                            ctx.lineWidth = 5
                            ctx.strokeStyle = "#ff4e71"
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, start, end)
                            ctx.stroke()
                        }
                    }

                    Connections {
                        target: root
                        function onProgressChanged() { subCanvas.requestPaint() }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(root.progress * 100) + "%"
                        color: "#ff4e71"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text { text: "Subscribers"; color: "#8a8a93"; font.pixelSize: 11; font.bold: true }
                    Text { text: root.subCount; color: "white"; font.pixelSize: 16; font.bold: true }
                    Text { text: "Goal: " + root.subGoal.toLocaleString(); color: "#5a5a63"; font.pixelSize: 10; font.bold: true }
                }
            }
        }

        // Card 2: Total Views
        Rectangle {
            width: 195
            height: 94
            color: "#1a1a1e"
            radius: 18

            Row {
                anchors.centerIn: parent
                spacing: 12

                Canvas {
                    id: viewsCanvas
                    width: 56
                    height: 56
                    anchors.verticalCenter: parent.verticalCenter

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2
                        var cy = height / 2
                        var r = (width - 8) / 2

                        ctx.lineWidth = 5
                        ctx.strokeStyle = "#2a2a32"
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                        ctx.stroke()

                        ctx.lineWidth = 5
                        ctx.strokeStyle = "#ffb020"
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI * 0.8)
                        ctx.stroke()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u25B6"
                        color: "#ffb020"
                        font.pixelSize: 13
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text { text: "Total Views"; color: "#8a8a93"; font.pixelSize: 11; font.bold: true }
                    Text { text: root.viewCount; color: "white"; font.pixelSize: 16; font.bold: true }
                    Text { text: "Channel Total"; color: "#5a5a63"; font.pixelSize: 10; font.bold: true }
                }
            }
        }
    }
}
