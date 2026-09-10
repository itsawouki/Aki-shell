import QtQuick
import QtQuick.Layouts
import "." as Modules

Item {
    id: row

    property string ssid: ""
    property int signalStrength: 0
    property bool secured: false
    property bool active: false

    signal connectRequested(string password)
    signal disconnectRequested()

    property bool expanded: false

    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        width: row.width
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: mainArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                WifiSignalIcon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 14
                    strength: row.signalStrength
                    active: row.active
                }

                Text {
                    Layout.fillWidth: true
                    text: row.ssid
                    color: "white"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Text {
                    visible: row.secured
                    text: "\u{1F512}"
                    font.pixelSize: 10
                    opacity: 0.5
                }

                Text {
                    visible: row.active
                    text: "Connected"
                    color: Modules.ThemeService.accentColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: mainArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (row.active) {
                        row.disconnectRequested()
                    } else if (row.secured) {
                        row.expanded = !row.expanded
                    } else {
                        row.connectRequested("")
                    }
                }
            }
        }

        // Inline password entry for secured, not-yet-connected networks
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: row.expanded ? 44 : 0
            clip: true
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 4
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: passwordField.activeFocus ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.5) : Qt.rgba(1, 1, 1, 0.08)

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"
                        font.pixelSize: 12
                        echoMode: TextInput.Password
                        clip: true
                        selectByMouse: true

                        Keys.onReturnPressed: row.connectRequested(passwordField.text)
                        Keys.onEnterPressed: row.connectRequested(passwordField.text)

                        Text {
                            visible: passwordField.text.length === 0
                            text: "Password"
                            color: Qt.rgba(1, 1, 1, 0.35)
                            font: passwordField.font
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 32
                    radius: 8
                    color: connectArea.containsMouse ? Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.3) : Modules.ThemeService.colorWithAlpha(Modules.ThemeService.accentColor, 0.18)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Join"
                        color: "white"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.connectRequested(passwordField.text)
                    }
                }
            }
        }
    }
}
