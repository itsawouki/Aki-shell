import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: powerView

    property bool active: false
    signal requestClose()

    onActiveChanged: {
        if (active) {
            focusRetry.attempts = 0
            focusRetry.start()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            powerView.forceActiveFocus()
            attempts++
            if (powerView.activeFocus || attempts > 15) stop()
        }
    }

    Keys.onEscapePressed: powerView.requestClose()

    // System commands
    Process { id: shutdownProc; command: ["systemctl", "poweroff"]; running: false }
    Process { id: rebootProc;   command: ["systemctl", "reboot"];   running: false }
    Process { id: suspendProc;  command: ["systemctl", "suspend"];  running: false }
    Process { id: lockProc;     command: ["hyprlock"];             running: false }

    function executeAction(proc) {
        powerView.requestClose()
        proc.running = false
        proc.running = true
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: [
                { name: "Shutdown", icon: "⏻", color: "#ff5555", proc: shutdownProc },
                { name: "Restart",  icon: "↻", color: "#ffb86c", proc: rebootProc },
                { name: "Sleep",    icon: "☾", color: "#8be9fd", proc: suspendProc },
                { name: "Lock",     icon: "🔒", color: "#bd93f9", proc: lockProc }
            ]

            delegate: Rectangle {
                id: btn
                required property var modelData

                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 16
                color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: mouseArea.containsMouse ? btn.modelData.color : Qt.rgba(1, 1, 1, 0.1)

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: btn.modelData.icon
                        color: mouseArea.containsMouse ? btn.modelData.color : "white"
                        font.pixelSize: 18
                        font.bold: true

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: btn.modelData.name
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: executeAction(btn.modelData.proc)
                }
            }
        }
    }
}
