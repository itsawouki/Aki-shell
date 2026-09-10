import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: notifView
    spacing: 12

    property var notification: null

    readonly property string rawIcon: notification?.appIcon ?? ""
    readonly property string resolvedIconSource: {
        if (rawIcon.length === 0) return ""
        if (rawIcon.includes("://") || rawIcon.startsWith("/")) return rawIcon
        return Quickshell.iconPath(rawIcon, true)
    }

    Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignVCenter
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.08)
        clip: true

        Image {
            id: iconImage
            anchors.fill: parent
            anchors.margins: 4
            source: notifView.resolvedIconSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            text: "\u{1F514}"
            font.pixelSize: 20
            opacity: 0.5
            visible: !iconImage.visible
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: notifView.notification?.summary
                || notifView.notification?.appName
                || "Notification"
            color: "white"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: notifView.notification?.body ?? ""
            visible: text.length > 0
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 13
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            Layout.fillWidth: true
        }
    }
}
