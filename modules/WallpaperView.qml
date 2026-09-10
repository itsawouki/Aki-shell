import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: wallpaperView

    property bool active: false
    signal requestClose()

    onActiveChanged: {
        if (active) {
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
            listView.forceActiveFocus()
            attempts++
            if (listView.activeFocus || attempts > 15) stop()
        }
    }

readonly property string wallpaperPath: Quickshell.env("HOME") + "/Pictures/Wallpapers/"

    Process {
        id: setWallProc
        property string selectedFile: ""
        command: ["awww", "img", wallpaperView.wallpaperPath + selectedFile]
        running: false
    }

    function applyWallpaper(fileName) {
        if (!fileName) return
        setWallProc.selectedFile = fileName
        setWallProc.running = false
        setWallProc.running = true
        wallpaperView.requestClose()
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + wallpaperView.wallpaperPath
        nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.webp", "*.JPG", "*.PNG"]
        showDirs: false
    }

    ListView {
        id: listView
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        model: folderModel

        snapMode: ListView.SnapToItem
        highlightMoveDuration: 220

        focus: wallpaperView.active
        keyNavigationEnabled: true

        Keys.onEscapePressed: wallpaperView.requestClose()
        Keys.onReturnPressed: {
            if (currentItem) wallpaperView.applyWallpaper(currentItem.fileName)
        }
        Keys.onSpacePressed: {
            if (currentItem) wallpaperView.applyWallpaper(currentItem.fileName)
        }

        WheelHandler {
            target: listView
            onWheel: (event) => {
                let delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                listView.contentX = Math.max(0, Math.min(listView.contentX - delta, listView.contentItem.width - listView.width))
            }
        }

        delegate: Item {
            id: delegateItem
            required property string fileName
            required property string fileUrl
            required property int index

            property bool isSelected: listView.currentIndex === index
            property bool isHovered: mouseArea.containsMouse

            width: 154
            height: 90

            // Animated Card Container
            Item {
                id: card
                anchors.fill: parent
                scale: delegateItem.isHovered ? 1.05 : (delegateItem.isSelected ? 1.02 : 0.96)

                // Spring scale transition
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.3
                    }
                }

                // Base Card Image Container
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: "#181818"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: fileUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        opacity: (delegateItem.isHovered || delegateItem.isSelected) ? 1.0 : 0.65

                        Behavior on opacity {
                            NumberAnimation { duration: 180 }
                        }
                    }

                    // Subtle ambient dark layer for non-hovered items
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: (delegateItem.isHovered || delegateItem.isSelected) ? 0.0 : 0.25

                        Behavior on opacity {
                            NumberAnimation { duration: 180 }
                        }
                    }
                }

                // Glass Border Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: "transparent"
                    border.width: delegateItem.isSelected ? 2 : (delegateItem.isHovered ? 1.5 : 1)
                    border.color: delegateItem.isSelected 
                        ? Qt.rgba(1, 1, 1, 0.85) 
                        : (delegateItem.isHovered ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.12))

                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }

                // Selection Badge (Checkmark)
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 20
                    height: 20
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.65)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.8)
                    opacity: delegateItem.isSelected ? 1 : 0
                    scale: delegateItem.isSelected ? 1 : 0.4

                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutBack
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        listView.currentIndex = index
                        wallpaperView.applyWallpaper(fileName)
                    }
                }
            }
        }
    }
}
