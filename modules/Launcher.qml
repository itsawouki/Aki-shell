import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "." as Modules

Item {
    id: launcher

    property bool active: false
    signal requestClose()

    function reset() {
        searchField.text = ""
        appList.currentIndex = 0
    }

    onActiveChanged: {
        if (active) {
            focusRetry.attempts = 0
            focusRetry.start()
        } else {
            reset()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            searchField.forceActiveFocus()
            attempts++
            if (searchField.activeFocus || attempts > 15) {
                stop()
            }
        }
    }

    property string query: searchField.text

    property var filteredApps: {
        const all = DesktopEntries.applications.values
        const q = query.trim().toLowerCase()
        if (q.length === 0) return all.slice(0, 8)
        return all.filter(app => {
            return (app.name && app.name.toLowerCase().includes(q))
                || (app.comment && app.comment.toLowerCase().includes(q))
                || (app.genericName && app.genericName.toLowerCase().includes(q))
        }).slice(0, 8)
    }

    function launch(app) {
        if (!app) return
        app.execute()
        requestClose()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: searchField.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: searchField.activeFocus
                ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5)
                : Qt.rgba(1, 1, 1, 0.08)

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "\u{1F50D}"
                    font.pixelSize: 14
                    opacity: 0.6
                }

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    color: "white"
                    font.pixelSize: 15
                    clip: true
                    selectByMouse: true
                    focus: true

                    // Reset selected list item back to top when typing search query
                    onTextChanged: appList.currentIndex = 0

                    Keys.onEscapePressed: launcher.requestClose()

                    // Safe Arrow key cycling
                    Keys.onDownPressed: (event) => {
                        if (appList.count > 0) {
                            appList.incrementCurrentIndex()
                            event.accepted = true
                        }
                    }

                    Keys.onUpPressed: (event) => {
                        if (appList.count > 0) {
                            appList.decrementCurrentIndex()
                            event.accepted = true
                        }
                    }

                    // Launch current highlighted app on Enter
                    Keys.onReturnPressed: (event) => {
                        launcher.launch(appList.currentApp)
                        event.accepted = true
                    }
                    Keys.onEnterPressed: (event) => {
                        launcher.launch(appList.currentApp)
                        event.accepted = true
                    }

                    Text {
                        visible: searchField.text.length === 0
                        text: "Search apps\u2026"
                        color: Qt.rgba(1, 1, 1, 0.35)
                        font: searchField.font
                    }
                }
            }
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: launcher.filteredApps
            currentIndex: 0
            highlightMoveDuration: 120
            keyNavigationEnabled: false

            // Bounds-safe reference to current active app
            property var currentApp: (model && model.length > currentIndex && currentIndex >= 0) 
                ? model[currentIndex] 
                : null

            delegate: Rectangle {
                id: delegateRoot
                required property var modelData
                required property int index

                width: appList.width
                height: 52
                radius: 10
                color: index === appList.currentIndex
                    ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.16)
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    IconImage {
                        implicitSize: 30
                        Layout.alignment: Qt.AlignVCenter
                        source: delegateRoot.modelData.icon
                            ? Quickshell.iconPath(delegateRoot.modelData.icon, true)
                            : ""
                        asynchronous: true

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.08)
                            visible: parent.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent
                                text: (delegateRoot.modelData.name || "?").charAt(0).toUpperCase()
                                color: "white"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: delegateRoot.modelData.name ?? ""
                            color: "white"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: !!delegateRoot.modelData.comment
                            text: delegateRoot.modelData.comment ?? ""
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: appList.currentIndex = delegateRoot.index
                    onClicked: launcher.launch(delegateRoot.modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: appList.count === 0
                text: "No matches"
                color: Qt.rgba(1, 1, 1, 0.35)
                font.pixelSize: 13
            }
        }
    }
}
