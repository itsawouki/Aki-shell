pragma Singleton
import QtQuick

QtObject {
    id: registry

    property var panels: []

    function register(panel) {
        panels.push(panel)
    }

    function unregister(panel) {
        const idx = panels.indexOf(panel)
        if (idx !== -1) panels.splice(idx, 1)
    }

    function toggleAll() {
        for (let i = 0; i < panels.length; i++) {
            if (panels[i]) panels[i].toggle()
        }
    }

    function openAll() {
        for (let i = 0; i < panels.length; i++) {
            if (panels[i]) panels[i].open()
        }
    }

    function closeAll() {
        for (let i = 0; i < panels.length; i++) {
            if (panels[i]) panels[i].close()
        }
    }
}
