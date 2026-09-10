import QtQuick
import "." as Modules

Item {
    id: icon

    property int strength: 0   // 0-100
    property bool active: false

    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            width: 3
            height: 4 + index * 4
            radius: 1
            x: index * 5
            y: icon.height - height
            color: (icon.strength >= (index + 1) * 30)
                ? (icon.active ? Modules.ThemeService.accentColor : "white")
                : Qt.rgba(1, 1, 1, 0.2)
            opacity: (icon.strength >= (index + 1) * 30) ? (icon.active ? 1 : 0.85) : 1
        }
    }
  }
