import QtQuick

Rectangle {
    id: button

    property string glyph: ""
    signal clicked()

    width: 30
    height: 30
    radius: 15
    color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)

    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: "white"
        font.pixelSize: 15
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
