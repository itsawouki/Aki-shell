import QtQuick
import QtQuick.Layouts

RowLayout {
    Layout.fillWidth: true
    spacing: 6

    property alias label: labelText.text
    property var value

    Text {
        id: labelText
        color: Qt.rgba(1, 1, 1, 0.5)
        font.pixelSize: 10
        font.family: "monospace"
        Layout.preferredWidth: 130
    }
    Text {
        text: String(value)
        color: "white"
        font.pixelSize: 10
        font.family: "monospace"
        elide: Text.ElideRight
        Layout.fillWidth: true
    }
}
