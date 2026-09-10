import QtQuick
import "." as Modules

Item {
    id: toggle

    property bool checked: false
    signal toggled()

    implicitWidth: 38
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: toggle.checked ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.9) : Qt.rgba(1, 1, 1, 0.14)
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        width: parent.height - 4
        height: parent.height - 4
        radius: height / 2
        color: "white"
        y: 2
        x: toggle.checked ? parent.width - width - 2 : 2
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled()
    }
}
