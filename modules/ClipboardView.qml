import "." as Modules
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: clipboardView

    property bool active: false
    signal requestClose()

    property string searchText: ""
    property var _modelData: []

    Timer {
        interval: 800
        running: clipboardView.active
        repeat: true
        onTriggered: refreshModel()
    }

    Connections {
        target: Modules.ClipboardService
        function onEntriesChanged() { refreshModel() }
    }

    onActiveChanged: {
        if (active) {
            searchText = ""
            searchInput.text = ""
            clipList.currentIndex = 0
            focusRetry.attempts = 0
            focusRetry.start()
            refreshModel()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            searchInput.forceActiveFocus()
            attempts++
            if (searchInput.activeFocus || attempts > 15) {
                stop()
            }
        }
    }

    function refreshModel() {
        const all = Modules.ClipboardService.entries
        if (searchText.length === 0) {
            _modelData = all.slice()
        } else {
            const q = searchText.toLowerCase()
            _modelData = all.filter(e => e.text.toLowerCase().includes(q))
        }
    }

    onSearchTextChanged: {
        refreshModel()
        clipList.currentIndex = 0
    }

    function selectEntry(entry) {
        if (!entry) return
        Modules.ClipboardService.copyToClipboard(entry.text)
        requestClose()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: searchInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: searchInput.activeFocus
                ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5)
                : Qt.rgba(1, 1, 1, 0.08)

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "\u{1F50D}"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.4)
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: "white"
                    font.pixelSize: 12
                    clip: true
                    focus: true
                    property string placeholder: "Search clipboard..."

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: searchInput.placeholder
                        color: Qt.rgba(1, 1, 1, 0.3)
                        font.pixelSize: 12
                        visible: searchInput.text.length === 0 && !searchInput.activeFocus
                    }

                    onTextChanged: clipboardView.searchText = text

                    Keys.onEscapePressed: clipboardView.requestClose()

                    Keys.onDownPressed: (event) => {
                        if (clipList.count > 0) {
                            clipList.incrementCurrentIndex()
                            event.accepted = true
                        }
                    }

                    Keys.onUpPressed: (event) => {
                        if (clipList.count > 0) {
                            clipList.decrementCurrentIndex()
                            event.accepted = true
                        }
                    }

                    Keys.onReturnPressed: (event) => {
                        clipboardView.selectEntry(clipList.currentEntry)
                        event.accepted = true
                    }
                    Keys.onEnterPressed: (event) => {
                        clipboardView.selectEntry(clipList.currentEntry)
                        event.accepted = true
                    }
                }

                Text {
                    text: "\u2715"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.4)
                    visible: searchInput.text.length > 0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        ListView {
            id: clipList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: clipboardView._modelData
            currentIndex: 0
            highlightMoveDuration: 0
            keyNavigationEnabled: false

            property var currentEntry: (model && model.length > currentIndex && currentIndex >= 0)
                ? model[currentIndex]
                : null

            highlight: Rectangle {
                radius: 8
                color: Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.16)
            }

            delegate: Rectangle {
                id: entryDelegate
                required property var modelData
                required property int index
                width: clipList.width
                height: entryRow.implicitHeight + 16
                radius: 8
                color: "transparent"

                RowLayout {
                    id: entryRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.fillHeight: true
                        radius: 1.5
                        color: Modules.ThemeService.accentColor
                    }

                    Text {
                        text: "\u{1F5BC}"
                        font.pixelSize: 12
                        color: Qt.rgba(1, 1, 1, 0.5)
                        visible: entryDelegate.modelData.isImage === true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: entryDelegate.modelData.preview ?? ""
                            color: "white"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }

                        Text {
                            text: {
                                const diff = Date.now() - entryDelegate.modelData.time
                                if (diff < 60000) return "just now"
                                if (diff < 3600000) return Math.floor(diff / 60000) + "m ago"
                                if (diff < 86400000) return Math.floor(diff / 3600000) + "h ago"
                                return Math.floor(diff / 86400000) + "d ago"
                            }
                            color: Qt.rgba(1, 1, 1, 0.35)
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: copyHover.containsMouse ? "#4ade80" : Qt.rgba(1, 1, 1, 0.08)
                        visible: entryDelegate.index === clipList.currentIndex || copyHover.containsMouse
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\u{1F4CB}"
                            font.pixelSize: 10
                        }
                        MouseArea {
                            id: copyHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Modules.ClipboardService.copyToClipboard(entryDelegate.modelData.text)
                        }
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: delHover.containsMouse ? "#ef4444" : Qt.rgba(1, 1, 1, 0.08)
                        visible: entryDelegate.index === clipList.currentIndex || delHover.containsMouse
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            font.pixelSize: 10
                            color: "white"
                        }
                        MouseArea {
                            id: delHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Modules.ClipboardService.removeEntry(entryDelegate.index)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: clipList.currentIndex = entryDelegate.index
                    onClicked: clipboardView.selectEntry(entryDelegate.modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: Modules.ClipboardService.entries.length === 0
                text: "Clipboard is empty"
                color: Qt.rgba(1, 1, 1, 0.35)
                font.pixelSize: 12
            }

            Text {
                anchors.centerIn: parent
                visible: Modules.ClipboardService.entries.length > 0 && clipList.count === 0
                text: "No matches"
                color: Qt.rgba(1, 1, 1, 0.35)
                font.pixelSize: 12
            }
        }
    }
}
