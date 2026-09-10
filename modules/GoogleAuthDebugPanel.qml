import "." as Modules
import QtQuick
import QtQuick.Layouts

// Drop this anywhere in the calendar UI (or even directly in the notch)
// to see GoogleAuth's live state without needing a terminal. Shows
// exactly which stage the flow is stuck at.
Rectangle {
    id: debugPanel

    color: "#000000"
    radius: 10
    border.width: 1
    border.color: Qt.rgba(1, 0.4, 0.4, 0.3)

    implicitHeight: content.implicitHeight + 20

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 4

        Text {
            text: "GoogleAuth debug"
            color: "#ff8080"
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        DebugRow { label: "credentialsLoaded"; value: Modules.GoogleAuth.credentialsLoaded }
        DebugRow { label: "hasCredentials"; value: Modules.GoogleAuth.hasCredentials }
        DebugRow { label: "clientId length"; value: Modules.GoogleAuth.clientId.length }
        DebugRow { label: "clientSecret length"; value: Modules.GoogleAuth.clientSecret.length }
        DebugRow { label: "isSignedIn"; value: Modules.GoogleAuth.isSignedIn }
        DebugRow { label: "syncInProgress"; value: Modules.GoogleAuth.syncInProgress }
        DebugRow { label: "lastError"; value: Modules.GoogleAuth.lastError || "(none)" }
        DebugRow { label: "credentialsPath"; value: Modules.GoogleAuth.credentialsPath }
        DebugRow { label: "codeCatcherScript"; value: Modules.GoogleAuth.codeCatcherScript }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            Layout.topMargin: 6
            radius: 6
            color: testArea.containsMouse ? Qt.rgba(1, 0.4, 0.4, 0.25) : Qt.rgba(1, 0.4, 0.4, 0.15)

            Text {
                anchors.centerIn: parent
                text: "Call syncNow() now"
                color: "#ff8080"
                font.pixelSize: 10
            }

            MouseArea {
                id: testArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Debug] manually calling GoogleAuth.syncNow()")
                    Modules.GoogleAuth.syncNow()
                }
            }
        }
    }
}
