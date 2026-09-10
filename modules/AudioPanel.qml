import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "." as Modules // needed for the AudioService singleton below

Rectangle {
    id: panel

    property bool expanded: false
    property bool showingDevices: false


    property int panelWidth: 180
    property int panelHeight: 360

    function open() { expanded = true }
    function close() { expanded = false; showingDevices = false }
    function toggle() { expanded = !expanded }

    width: expanded ? panelWidth : 0
    height: panelHeight
    color: "#171717"
    clip: true
    antialiasing: true

    // Flush with the right screen edge, rounded only on the inward side —
    // the mirror image of the top island's bottomLeft/bottomRight-only radius.
    radius: 26
    topLeftRadius: radius
    bottomLeftRadius: radius
    topRightRadius: 0
    bottomRightRadius: 0

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.55
        shadowBlur: 1
        shadowHorizontalOffset: -3
    }

    Behavior on width {
        NumberAnimation { duration: 260; easing.type: Easing.OutExpo }
    }

    focus: true
    Keys.onEscapePressed: panel.close()

    onExpandedChanged: {
        if (expanded) {
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
            panel.forceActiveFocus()
            attempts++
            if (panel.activeFocus || attempts > 15) stop()
        }
    }

    // --- Volume view ---------------------------------------------------
    Item {
        id: mainView
        anchors.fill: parent
        anchors.margins: 18
        opacity: (panel.expanded && !panel.showingDevices) ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            Text {
                text: "Sound"
                color: "white"
                font.pixelSize: 15
                font.weight: Font.ExtraBold
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                Item { Layout.fillWidth: true }

                VolumeSlider {
                    Layout.fillHeight: true
                    label: "Output"
                    glyph: muted ? "\u{1F507}" : "\u{1F50A}"
                    value: Modules.AudioService.sinkVolume
                    muted: Modules.AudioService.sinkMuted
                    onValueEdited: v => Modules.AudioService.setSinkVolume(v)
                    onGlyphClicked: Modules.AudioService.toggleSinkMute()
                }

                VolumeSlider {
                    Layout.fillHeight: true
                    label: "Mic"
                    glyph: muted ? "\u{1F507}" : "\u{1F3A4}"
                    value: Modules.AudioService.sourceVolume
                    muted: Modules.AudioService.sourceMuted
                    onValueEdited: v => Modules.AudioService.setSourceVolume(v)
                    onGlyphClicked: Modules.AudioService.toggleSourceMute()
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                color: sourceMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.06)
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                   // Text { text: "\u{1F501}"; font.pixelSize: 14; opacity: 0.85 }
                    Text {
                        text: "Change Source"
                        color: "white"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: sourceMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.showingDevices = true
                }
            }
        }
    }    // --- Device picker view --------------------------------------------
    Item {
        id: deviceView
        anchors.fill: parent
        anchors.margins: 18
        opacity: (panel.expanded && panel.showingDevices) ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            RowLayout {
                spacing: 8

                MediaButton {
                    glyph: "\u{2039}"
                    big: true
                    onClicked: panel.showingDevices = false
                }
                Text {
                    text: "Audio Devices"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.ExtraBold
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: deviceColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: deviceColumn
                    width: parent.width
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "OUTPUT"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }

                        Repeater {
                            model: Modules.AudioService.outputs
                            delegate: AudioDeviceOption {
                                required property var modelData
                                Layout.fillWidth: true
                                label: modelData.description || modelData.name
                                selected: modelData === Modules.AudioService.sink
                                onClicked: Modules.AudioService.selectOutput(modelData)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "INPUT"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }

                        Repeater {
                            model: Modules.AudioService.inputs
                            delegate: AudioDeviceOption {
                                required property var modelData
                                Layout.fillWidth: true
                                label: modelData.description || modelData.name
                                selected: modelData === Modules.AudioService.source
                                onClicked: Modules.AudioService.selectInput(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
