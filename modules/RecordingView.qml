import QtQuick
import QtQuick.Layouts

Item {
    id: recordingView

    // "recording", "paused", or "off"
    property string status: "off"
    property int secondsElapsed: 0

    // Timer only ticks while actively recording
    Timer {
        interval: 1000
        running: recordingView.status === "recording"
        repeat: true
        onTriggered: recordingView.secondsElapsed++
    }

    onStatusChanged: {
        if (status === "off") {
            secondsElapsed = 0
        }
    }

    function formatTime(totalSecs) {
        let m = Math.floor(totalSecs / 60)
        let s = totalSecs % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    readonly property bool isPaused: status === "paused"

    RowLayout {
        anchors.centerIn: parent
        spacing: 12

        // Status Pill Capsule
        Rectangle {
            implicitWidth: recordingView.isPaused ? 68 : 54
            implicitHeight: 22
            radius: 11
            color: recordingView.isPaused ? Qt.rgba(1, 0.84, 0.04, 0.16) : Qt.rgba(1, 0.23, 0.19, 0.16)
            border.width: 1
            border.color: recordingView.isPaused ? Qt.rgba(1, 0.84, 0.04, 0.35) : Qt.rgba(1, 0.23, 0.19, 0.35)

            Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                // Indicator (Red Pulsing Dot OR Amber Pause Bars)
                Item {
                    implicitWidth: 10
                    implicitHeight: 10

                    // Red Pulsing Halo (Recording)
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: "transparent"
                        border.width: 1.5
                        border.color: "#ff3b30"
                        visible: !recordingView.isPaused

                        SequentialAnimation on scale {
                            running: recordingView.status === "recording"
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.8; to: 1.6; duration: 900; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.6; to: 0.8; duration: 900; easing.type: Easing.InOutQuad }
                        }

                        SequentialAnimation on opacity {
                            running: recordingView.status === "recording"
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.8; to: 0.0; duration: 900; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.0; to: 0.8; duration: 900; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Red Core Dot (Recording)
                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: "#ff3b30"
                        visible: !recordingView.isPaused
                    }

                    // Amber Pause Icon (Paused)
                    Text {
                        anchors.centerIn: parent
                        text: "❚❚"
                        color: "#ffd60a"
                        font.pixelSize: 8
                        visible: recordingView.isPaused
                    }
                }

                // Text Badge
                Text {
                    text: recordingView.isPaused ? "PAUSED" : "REC"
                    color: recordingView.isPaused ? "#ffd60a" : "#ff453a"
                    font.pixelSize: 10
                    font.weight: Font.Black
                    font.letterSpacing: 0.6
                }
            }
        }

        // Live / Frozen Timer
        Text {
            text: recordingView.formatTime(recordingView.secondsElapsed)
            color: recordingView.isPaused ? "#d1d1d6" : "#ffffff"
            font.pixelSize: 13
            font.weight: Font.Bold
            font.letterSpacing: 0.8
        }
    }
}
