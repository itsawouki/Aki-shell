import "." as Modules
import QtQuick
import QtQuick.Layouts

Item {
    id: calendarView

    signal requestClose()

    property date today: new Date()
    property int selectedDayOffset: 0 // 0 = Mon ... 6 = Sun

    // Silent background refresh whenever the calendar is opened
    onVisibleChanged: {
        if (visible && Modules.GoogleAuth.isSignedIn && !Modules.GoogleAuth.syncInProgress) {
            Modules.CalendarService.fetchCurrentWeek()
        }
    }

    // Monday of current week
    property date weekStart: {
        const d = new Date(today)
        const day = d.getDay()
        const diff = d.getDate() - day + (day === 0 ? -6 : 1)
        return new Date(d.getFullYear(), d.getMonth(), diff)
    }

    property date selectedDate: {
        const d = new Date(weekStart)
        d.setDate(d.getDate() + selectedDayOffset)
        return d
    }

    function _isSameDay(a, b) {
        if (!a || !b) return false
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    // --- Automatic Sync on Boot / Startup ---
    Timer {
        id: bootSyncTimer
        interval: 3000 // Waits 3 seconds for network/services to initialize
        running: true
        repeat: false
        onTriggered: {
            if (!Modules.GoogleAuth.isSignedIn) {
                Modules.GoogleAuth.syncNow()
            } else {
                Modules.CalendarService.fetchCurrentWeek()
            }
        }
    }

    // --- Periodic Silent Background Refresh (Every 5 minutes) ---
    Timer {
        id: autoRefreshTimer
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: {
            if (Modules.GoogleAuth.isSignedIn && !Modules.GoogleAuth.syncInProgress) {
                Modules.CalendarService.fetchCurrentWeek()
            }
        }
    }

    Component.onCompleted: {
        const curDay = today.getDay()
        selectedDayOffset = curDay === 0 ? 6 : curDay - 1
        if (Modules.GoogleAuth.isSignedIn) Modules.CalendarService.fetchCurrentWeek()
    }

    Connections {
        target: Modules.GoogleAuth
        function onSignedIn() { Modules.CalendarService.fetchCurrentWeek() }
    }

    property var dayEvents: {
        return Modules.CalendarService.events.filter(ev => {
            const d = ev.allDay ? new Date(ev.start + "T00:00:00") : new Date(ev.start)
            return calendarView._isSameDay(d, calendarView.selectedDate)
        }).sort((a, b) => a.allDay ? -1 : (a.start < b.start ? -1 : 1))
    }

    function getEventCountForOffset(offset) {
        const target = new Date(weekStart)
        target.setDate(target.getDate() + offset)
        return Modules.CalendarService.events.filter(ev => {
            const d = ev.allDay ? new Date(ev.start + "T00:00:00") : new Date(ev.start)
            return calendarView._isSameDay(d, target)
        }).length
    }

    // --- Background Frame ---
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#202124"
        border.width: 1
        border.color: "#3c4043"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // --- Header Row ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Google Calendar Mini Icon
                Rectangle {
                    width: 22; height: 22; radius: 5
                    color: "#303134"
                    border.width: 1; border.color: "#5f6368"

                    Text {
                        anchors.centerIn: parent
                        text: calendarView.today.getDate()
                        color: Modules.ThemeService.accentColor
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: Qt.formatDate(calendarView.selectedDate, "MMMM yyyy")
                    color: "#e8eaed"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }
            }

            // --- Compact 7-Day Week Strip ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    delegate: Rectangle {
                        id: dayCell
                        required property int index
                        required property string modelData

                        property date cellDate: {
                            const d = new Date(calendarView.weekStart)
                            d.setDate(d.getDate() + index)
                            return d
                        }
                        property bool isSelected: calendarView.selectedDayOffset === index
                        property bool isToday: calendarView._isSameDay(cellDate, calendarView.today)
                        property int eventCount: calendarView.getEventCountForOffset(index)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: dayMouse.containsMouse && !isSelected ? "#2d2e31" : "transparent"

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: dayCell.modelData
                                color: dayCell.isToday ? Modules.ThemeService.accentColor : "#9aa0a6"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }

                            // Compact Date Circle
                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignHCenter
                                radius: 10
                                color: dayCell.isSelected 
                                    ? Modules.ThemeService.accentColor 
                                    : (dayCell.isToday ? "#3c4043" : "transparent")
                                border.width: dayCell.isToday && !dayCell.isSelected ? 1 : 0
                                border.color: Modules.ThemeService.accentColor

                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.cellDate.getDate()
                                    color: dayCell.isSelected 
                                        ? "#202124" 
                                        : (dayCell.isToday ? Modules.ThemeService.accentColor : "#e8eaed")
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Bottom Event Indicator
                        Rectangle {
                            visible: dayCell.eventCount > 0
                            width: 3; height: 3; radius: 1.5
                            color: dayCell.isSelected ? Modules.ThemeService.accentColor : "#9aa0a6"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarView.selectedDayOffset = dayCell.index
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#3c4043"
            }

            // --- Agenda Tasks View ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                Text {
                    text: Qt.formatDate(calendarView.selectedDate, "dddd, MMMM d")
                    color: "#9aa0a6"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: calendarView.dayEvents
                    visible: calendarView.dayEvents.length > 0

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 36
                        radius: 6
                        color: "#2d2e31"
                        border.width: 1
                        border.color: "#3c4043"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.fillHeight: true
                                Layout.topMargin: 5
                                Layout.bottomMargin: 5
                                radius: 1.5
                                color: Modules.ThemeService.accentColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: modelData.summary
                                    color: "#e8eaed"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.allDay
                                        ? "All day"
                                        : Qt.formatTime(new Date(modelData.start), "hh:mm") + " – " + Qt.formatTime(new Date(modelData.end), "hh:mm")
                                    color: "#9aa0a6"
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }

                // Empty state (only shown when there truly are no events for the day)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: calendarView.dayEvents.length === 0

                    Item { Layout.fillHeight: true }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Modules.GoogleAuth.isSignedIn ? "No events scheduled for this day" : "Sync with Google to view calendar"
                        color: "#9aa0a6"
                        font.pixelSize: 10
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
