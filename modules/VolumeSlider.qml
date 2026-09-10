import QtQuick
import QtQuick.Layouts
import "." as Modules

Item {
    id: root

    property string label: ""
    property string glyph: ""
    property real value: 0
    property bool muted: false

    signal valueEdited(real value)
    signal glyphClicked()

    implicitWidth: 64

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.muted ? "Muted" : Math.round(root.value * 100) + "%"
            color: root.muted ? Qt.rgba(1, 0.45, 0.45, 0.9) : Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 11
        }

        Item {
            id: track
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.alignment: Qt.AlignHCenter
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * Math.max(0, Math.min(1, root.value))
                radius: track.width / 2
                color: root.muted ? Qt.rgba(1, 1, 1, 0.25) : Modules.ThemeService.accentColor
                Behavior on height {
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                onPressed: mouse => updateFromY(mouse.y)
                onPositionChanged: mouse => { if (pressed) updateFromY(mouse.y) }

                function updateFromY(y) {
                    const clampedY = Math.max(0, Math.min(track.height, y))
                    root.valueEdited(1 - (clampedY / track.height))
                }
            }
        }

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignHCenter

            Text {
                anchors.centerIn: parent
                text: root.glyph
                font.pixelSize: 15
                opacity: root.muted ? 0.4 : (glyphArea.containsMouse ? 0.85 : 1)
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                id: glyphArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.glyphClicked()
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            color: Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }
}
