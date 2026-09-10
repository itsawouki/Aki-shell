import QtQuick
import QtQuick.Layouts
import "." as Modules

Item {
    id: musicView

    property bool active: false
    signal requestClose()

    // Refresh list every time the view becomes active
    onActiveChanged: {
        if (active) {
            Modules.MusicService.refresh()
            list.currentIndex = 0
            focusRetry.attempts = 0
            focusRetry.start()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            list.forceActiveFocus()
            attempts++
            if (list.activeFocus || attempts > 15) stop()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Playlists"
                color: "white"
                font.pixelSize: 16
                font.weight: Font.ExtraBold
            }

            Item { Layout.fillWidth: true }

            // Stop button (only when something is playing)
            Rectangle {
                visible: Modules.MusicService.isPlaying
                Layout.preferredWidth: stopLabel.implicitWidth + 20
                Layout.preferredHeight: 28
                radius: 8
                color: stopArea.containsMouse ? Qt.rgba(1, 0.4, 0.4, 0.25) : Qt.rgba(1, 0.4, 0.4, 0.12)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: stopLabel
                    anchors.centerIn: parent
                    text: "Stop"
                    color: "#ff8a8a"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: stopArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Modules.MusicService.stop()
                }
            }

            // Close
            MediaButton {
                glyph: "\u2715"
                onClicked: musicView.requestClose()
            }
        }

        // Current playing indicator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Modules.MusicService.isPlaying ? 36 : 0
            radius: 10
            color: Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.12)
            visible: height > 0
            clip: true
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "\u{1F3B5}"
                    font.pixelSize: 13
                }
                Text {
                    text: Modules.MusicService.currentPlaylist
                    color: Modules.ThemeService.accentColor
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: "playing"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: 11
                }
            }
        }

        // Playlist list
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: Modules.MusicService.playlists
            currentIndex: 0
            highlightMoveDuration: 120
            keyNavigationEnabled: true
            focus: true

            Keys.onEscapePressed: musicView.requestClose()
            Keys.onReturnPressed: {
                if (currentItem) {
                    Modules.MusicService.play(currentItem.modelData.name)
                    musicView.requestClose()
                }
            }
            Keys.onEnterPressed: {
                if (currentItem) {
                    Modules.MusicService.play(currentItem.modelData.name)
                    musicView.requestClose()
                }
            }

            delegate: Rectangle {
                id: delegateRoot
                required property var modelData
                required property int index

                width: list.width
                height: 48
                radius: 12
                color: {
                    if (index === list.currentIndex)
                        return Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.18)
                    if (Modules.MusicService.currentPlaylist === modelData.name)
                        return Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.08)
                    return "transparent"
                }
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Folder icon
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "\u{1F4C1}"
                            font.pixelSize: 14
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: modelData.name
                            color: "white"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Modules.MusicService.currentPlaylist === modelData.name
                                  ? "Now playing"
                                  : "Folder"
                            color: Modules.MusicService.currentPlaylist === modelData.name
                                   ? Modules.ThemeService.accentColor
                                   : Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 11
                        }
                    }

                    // Play indicator
                    Text {
                        visible: Modules.MusicService.currentPlaylist === modelData.name
                        text: "\u{25B6}"
                    color: Modules.ThemeService.accentColor
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = index
                    onClicked: {
                        Modules.MusicService.play(modelData.name)
                        musicView.requestClose()
                    }
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\u{1F3B5}"
                    font.pixelSize: 28
                    opacity: 0.3
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No playlists found"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: 13
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Put folders in ~/Music"
                    color: Qt.rgba(1, 1, 1, 0.25)
                    font.pixelSize: 11
                }
            }
        }

        // Hint
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enter to play  ·  Esc to close"
            color: Qt.rgba(1, 1, 1, 0.25)
            font.pixelSize: 10
            visible: list.count > 0
        }
    }
}
