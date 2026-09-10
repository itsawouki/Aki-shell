import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Item {
    id: mediaView

    property var players: Mpris.players.values
    property bool hasPlayer: players.length > 0

    RowLayout {
        anchors.fill: parent
        visible: !mediaView.hasPlayer
        spacing: 10

        Item { Layout.fillWidth: true }
        Text {
            text: "\u{1F3B5}"
            font.pixelSize: 18
            opacity: 0.4
        }
        Text {
            text: "Nothing playing"
            color: Qt.rgba(1, 1, 1, 0.4)
            font.pixelSize: 13
        }
        Item { Layout.fillWidth: true }
    }

    ListView {
        id: playerList
        anchors.fill: parent
        visible: mediaView.hasPlayer
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        clip: true
        model: mediaView.players

        delegate: Item {
            id: card
            required property var modelData
            width: playerList.width
            height: playerList.height

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    id: artFrame
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    Layout.alignment: Qt.AlignVCenter
                    radius: 9
                    color: Qt.rgba(1, 1, 1, 0.08)
                    clip: true

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: card.modelData?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u{1F3B6}"
                        font.pixelSize: 16
                        opacity: 0.4
                        visible: !artImage.visible
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 130
                    spacing: 1

                    Text {
                        text: card.modelData?.trackTitle || "Unknown Title"
                        color: "white"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: card.modelData?.trackArtist || "Unknown Artist"
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 10
                        Layout.topMargin: 4

                        MediaButton {
                            glyph: "\u{23EE}"
                            enabled: card.modelData?.canGoPrevious ?? false
                            onClicked: card.modelData?.previous()
                        }
                        MediaButton {
                            glyph: card.modelData?.isPlaying ? "\u{23F8}" : "\u{25B6}"
                            enabled: card.modelData?.canTogglePlaying ?? false
                            onClicked: card.modelData?.togglePlaying()
                        }
                        MediaButton {
                            glyph: "\u{23ED}"
                            enabled: card.modelData?.canGoNext ?? false
                            onClicked: card.modelData?.next()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                ClockPanel {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                }
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 2
        spacing: 4
        visible: mediaView.players.length > 1

        Repeater {
            model: mediaView.players.length
            delegate: Rectangle {
                required property int index
                width: 4; height: 4; radius: 2
                color: index === playerList.currentIndex
                    ? Qt.rgba(1, 1, 1, 0.8)
                    : Qt.rgba(1, 1, 1, 0.25)
            }
        }
    }
}
