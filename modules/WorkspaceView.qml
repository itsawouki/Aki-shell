import QtQuick
import QtQuick.Layouts

Item {
    id: workspaceView

    property int activeWs: 1

    RowLayout {
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: 5

            delegate: Item {
                id: dotContainer
                required property int index
                property int wsNum: index + 1
                property bool isActive: workspaceView.activeWs === wsNum

                implicitWidth: 16
                implicitHeight: 16

                // Outer ambient halo ring for active dot
                Rectangle {
                    anchors.centerIn: parent
                    width: dotContainer.isActive ? 16 : 0
                    height: dotContainer.isActive ? 16 : 0
                    radius: width / 2
                    color: "transparent"
                    border.width: 1.5
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    opacity: dotContainer.isActive ? 1 : 0

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Core Circle
                Rectangle {
                    anchors.centerIn: parent
                    width: dotContainer.isActive ? 8 : 6
                    height: dotContainer.isActive ? 8 : 6
                    radius: width / 2

                    color: dotContainer.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.25)

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
