import QtQuick
import QtQuick.Layouts
import "." as Modules

Item {
    id: option

    property string label: ""
    property bool selected: false
    signal clicked()

    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: "transparent"
            border.width: 1.5
            border.color: option.selected ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.3)
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Modules.ThemeService.accentColor
                visible: option.selected
            }
        }

        Text {
            Layout.fillWidth: true
            text: option.label
            color: "white"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: option.clicked()
    }
}
