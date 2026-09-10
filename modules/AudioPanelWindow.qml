import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "." as Modules

PanelWindow {
    id: panelWindow

    required property var modelData
    screen: modelData

    property alias panel: audioPanel

    property var hyprMonitor: Hyprland.monitorFor(screen)
    property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false

    color: "transparent"

    // Unlike the top island (anchored/sized to its own content), this
    // window spans the whole output. That's what lets it host an
    // invisible full-screen click-catcher for "auto-close on click-away"
    // while the actual panel stays docked to the right edge.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: !monitorHasFullscreen

    // Only the visible panel blocks/receives input when closed. While
    // open, the mask grows to the full screen so an outside click can
    // reach our own click-catcher instead of passing through to the
    // window underneath.
    mask: Region {
        item: audioPanel.expanded ? clickCatcher : audioPanel
    }

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "myshell-audio-notch"

    WlrLayershell.keyboardFocus: audioPanel.expanded
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    onMonitorHasFullscreenChanged: {
        if (monitorHasFullscreen) audioPanel.close()
    }

    Component.onCompleted: Modules.AudioNotchRegistry.register(audioPanel)
    Component.onDestruction: Modules.AudioNotchRegistry.unregister(audioPanel)

    Item {
        id: clickCatcher
        anchors.fill: parent
        visible: audioPanel.expanded

        MouseArea {
            anchors.fill: parent
            onClicked: audioPanel.close()
        }
    }

    AudioPanel {
        id: audioPanel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
