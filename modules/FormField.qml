import QtQuick
import QtQuick.Layouts
import "." as Modules

Rectangle {
    id: field

    property alias text: input.text
    property string placeholder: ""
    signal accepted()

    Layout.fillWidth: true
    Layout.preferredHeight: 36
    radius: 10
    color: Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    border.color: input.activeFocus ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5) : Qt.rgba(1, 1, 1, 0.08)

    Behavior on border.color { ColorAnimation { duration: 120 } }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: "white"
        font.pixelSize: 12
        clip: true
        selectByMouse: true

        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()

        Text {
            visible: input.text.length === 0
            text: field.placeholder
            color: Qt.rgba(1, 1, 1, 0.35)
            font: input.font
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
