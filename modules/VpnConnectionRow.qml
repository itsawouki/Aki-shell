import QtQuick
import QtQuick.Layouts
import "." as Modules

Item {
    id: row

    property string label: ""
    property bool active: false
    signal clicked()

    implicitHeight: 38

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
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: row.active ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.25)
        }

        Text {
            Layout.fillWidth: true
            text: row.label
            color: "white"
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Text {
            visible: row.active
            text: "Active"
            color: Modules.ThemeService.accentColor
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
