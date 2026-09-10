import "." as Modules
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: clockPanel
    spacing: 8

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockPanel.now = new Date()
    }

    Text {
        text: {
            var h = clockPanel.now.getHours() % 12; if (h === 0) h = 12
            return h + ":" + (clockPanel.now.getMinutes() < 10 ? "0" : "") + clockPanel.now.getMinutes()
        }
        color: "white"
        font.pixelSize: 20
        font.weight: Font.ExtraBold
        Layout.alignment: Qt.AlignHCenter
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 5

        Repeater {
            model: 7

            delegate: ColumnLayout {
                required property int index
                spacing: 2

                property int todayIndex: (clockPanel.now.getDay() + 6) % 7
                property bool isToday: index === todayIndex
                property var dayLabels: ["M", "T", "W", "T", "F", "S", "S"]

                Text {
                    text: parent.dayLabels[parent.index]
                    color: parent.isToday ? "white" : Qt.rgba(1, 1, 1, 0.35)
                    font.pixelSize: 9
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignHCenter
                    radius: 8
                    color: parent.isToday ? Modules.ThemeService.accentColor : "transparent"
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Modules.CalendarPanelRegistry.openAll()
    }
}
