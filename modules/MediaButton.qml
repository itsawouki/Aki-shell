import QtQuick

Item {
    id: button

    property string glyph: ""
    property bool big: false
    signal clicked()

    width: big ? 26 : 20
    height: width
    opacity: !enabled ? 0.3 : (mouseArea.pressed ? 0.55 : (mouseArea.containsMouse ? 0.85 : 1))

    Behavior on opacity { NumberAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: "white"
        font.pixelSize: button.big ? 15 : 12
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: button.enabled
        onClicked: button.clicked()
    }
}
