import Quickshell
import Quickshell.Wayland
import QtQuick
import "." as Modules

PanelWindow {
    id: welcomeWindow

    required property var modelData
    screen: modelData
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property var svc: Modules.FirstRunService
    readonly property bool isHero: svc.stage === "hero"
    readonly property bool isFeatures: svc.stage === "features"
    readonly property bool isLeaving: svc.stage === "leaving"
    readonly property color accent: Modules.ThemeService.accentColor

    visible: svc.checked && svc.isFirstRun && svc.stage !== "done"

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aki-welcome"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: welcomeWindow.visible ? fullArea : nullMask
    }

    Item { id: nullMask; width: 0; height: 0; visible: false }
    Item { id: fullArea; anchors.fill: parent }

    property bool shown: false
    property int burstTick: 0
    property var sfxUnlock: null

    onIsFeaturesChanged: if (isFeatures) burstTick++

    Timer {
        id: enterTimer
        interval: 60
        onTriggered: welcomeWindow.shown = true
    }

    Component.onCompleted: {
        Modules.FirstRunService.ensureSfx()
        enterTimer.start()
        try { sfxUnlock = Qt.createQmlObject('import QtMultimedia; SoundEffect { source: "file://' + Quickshell.env("HOME") + '/.config/Aki-Shell/assets/sfx/unlock.wav" }', welcomeWindow) } catch(e) {}
    }

        Item {
            id: contentFade
            anchors.fill: parent
            opacity: welcomeWindow.isLeaving || !welcomeWindow.shown ? 0 : 1
        Behavior on opacity {
            NumberAnimation { duration: welcomeWindow.isLeaving ? 480 : 500; easing.type: Easing.InOutQuad }
        }
        focus: true
        Keys.onEscapePressed: Modules.FirstRunService.finish()

        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: "#0a0a0c"

            Rectangle {
                id: orbA
                width: 620; height: 620; radius: 310
                x: parent.width * 0.15 - 200
                y: parent.height * 0.2 - 150
                color: Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, 0.07)

                SequentialAnimation on x {
                    running: welcomeWindow.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: orbA.x + 90; duration: 9000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: orbA.x; duration: 9000; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on y {
                    running: welcomeWindow.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: orbA.y + 60; duration: 11000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: orbA.y; duration: 11000; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                id: orbB
                width: 520; height: 520; radius: 260
                x: parent.width * 0.72 - 120
                y: parent.height * 0.62 - 140
                color: Modules.ThemeService.colorWithAlpha("#a78bfa", 0.06)

                SequentialAnimation on x {
                    running: welcomeWindow.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: orbB.x - 70; duration: 10000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: orbB.x; duration: 10000; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.55) }
                    GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0) }
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.65) }
                }
            }
        }

        Rectangle {
            id: flash
            anchors.fill: parent
            color: welcomeWindow.accent
            opacity: 0
        }

        // ---------- HERO ----------
        Item {
            id: heroBlock
            anchors.fill: parent
            opacity: welcomeWindow.isHero ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity {
                NumberAnimation { duration: welcomeWindow.isHero ? 400 : 260; easing.type: Easing.OutCubic }
            }

            Column {
                anchors.centerIn: parent
                spacing: 14
                width: Math.min(parent.width - 80, 640)

                Item {
                    width: parent.width
                    height: 34

                    Rectangle {
                        id: badge
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 30
                        width: badgeText.implicitWidth + 36
                        radius: 15
                        color: Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, 0.10)
                        border.width: 1
                        border.color: Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, 0.45)

                        opacity: welcomeWindow.shown ? 1 : 0
                        y: welcomeWindow.shown ? 0 : -12
                        Behavior on opacity { NumberAnimation { duration: 350 } }
                        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: "✦  A K I   S H E L L  ✦"
                            color: welcomeWindow.accent
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                        }
                    }
                }

                Text {
                    id: greetTitle
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Hello, " + welcomeWindow.svc.greetingName + "."
                    color: "white"
                    font.pixelSize: 44
                    font.weight: Font.ExtraBold

                    opacity: welcomeWindow.shown ? 1 : 0
                    scale: welcomeWindow.shown ? 1 : 0.92
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                }

                Text {
                    id: greetSub
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Welcome to Aki Shell — your desktop, distilled into one little island."
                    color: "#9aa0a6"
                    font.pixelSize: 15

                    opacity: welcomeWindow.shown ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                }

                Item { width: 1; height: 34 }

                Item {
                    id: diveWrap
                    width: parent.width
                    height: 210

                    opacity: welcomeWindow.shown ? 1 : 0
                    scale: welcomeWindow.shown ? 1 : 0.9
                    Behavior on opacity { NumberAnimation { duration: 450 } }
                    Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

                    Item {
                        id: diveButton
                        width: 156
                        height: 156
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter

                        property real holdProgress: 0
                        property bool holding: false

                        Rectangle {
                            id: glowHalo
                            anchors.centerIn: parent
                            width: 130 + 46 * diveButton.holdProgress
                            height: width
                            radius: width / 2
                            color: Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, 0.08 + 0.22 * diveButton.holdProgress)
                        }

                        Canvas {
                            id: ringCanvas
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()
                                const c = width / 2
                                const r = 70
                                ctx.lineWidth = 5
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(c, c, r, 0, Math.PI * 2)
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.09)
                                ctx.stroke()
                                if (diveButton.holdProgress > 0.001) {
                                    ctx.beginPath()
                                    ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * diveButton.holdProgress)
                                    ctx.strokeStyle = welcomeWindow.accent
                                    ctx.shadowColor = welcomeWindow.accent
                                    ctx.shadowBlur = 14
                                    ctx.stroke()
                                }
                            }
                            Connections {
                                target: diveButton
                                function onHoldProgressChanged() { ringCanvas.requestPaint() }
                            }
                        }

                        Rectangle {
                            id: innerCircle
                            anchors.centerIn: parent
                            width: 122
                            height: 122
                            radius: 61
                            color: "#141416"
                            border.width: 1
                            border.color: diveButton.holding
                                ? welcomeWindow.accent
                                : Qt.rgba(1, 1, 1, 0.08)
                            scale: 1 + 0.11 * diveButton.holdProgress
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            Text {
                                id: rocketIcon
                                anchors.centerIn: parent
                                text: "🚀"
                                font.pixelSize: 38
                                rotation: -12 + 24 * diveButton.holdProgress
                            }
                        }

                        MouseArea {
                            id: holdArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: welcomeWindow.isHero
                            onPressed: {
                                diveButton.holding = true
                                Modules.FirstRunService.playSfx("press")
                                holdDownAnim.stop()
                                holdUpAnim.start()
                            }
                            onReleased: {
                                diveButton.holding = false
                                if (!holdUpAnim.running) return
                                holdUpAnim.stop()
                                holdDownAnim.restart()
                            }
                            onCanceled: {
                                diveButton.holding = false
                                holdUpAnim.stop()
                                holdDownAnim.restart()
                            }
                        }

                        NumberAnimation {
                            id: holdUpAnim
                            target: diveButton
                            property: "holdProgress"
                            to: 1
                            duration: 3000
                            onStopped: {
                                if (diveButton.holdProgress >= 0.999 && welcomeWindow.isHero) {
                                    if (welcomeWindow.sfxUnlock) welcomeWindow.sfxUnlock.play()
                                    Modules.FirstRunService.completeHold()
                                }
                            }
                        }
                        NumberAnimation {
                            id: holdDownAnim
                            target: diveButton
                            property: "holdProgress"
                            to: 0
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        id: holdLabel
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (!diveButton.holding && diveButton.holdProgress <= 0) return "Hold to dive in"
                            if (diveButton.holdProgress >= 1) return "Welcome aboard ✦"
                            return "Keep holding…"
                        }
                        color: diveButton.holdProgress > 0 ? welcomeWindow.accent : "#9aa0a6"
                        font.pixelSize: 13
                        font.weight: Font.Medium

                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }
            }
        }

        // ---------- BURST FX ----------
        Item {
            id: burstLayer
            anchors.fill: parent
            visible: burstTick > 0

            Rectangle {
                id: ring1
                width: 150; height: 150; radius: 75
                anchors.centerIn: parent
                color: "transparent"
                border.width: 2
                border.color: welcomeWindow.accent
                opacity: 0
            }
            Rectangle {
                id: ring2
                width: 150; height: 150; radius: 75
                anchors.centerIn: parent
                color: "transparent"
                border.width: 2
                border.color: Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, 0.7)
                opacity: 0
            }
            Rectangle {
                id: ring3
                width: 150; height: 150; radius: 75
                anchors.centerIn: parent
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.8)
                opacity: 0
            }

            Repeater {
                id: particles
                model: 24
                delegate: Rectangle {
                    id: particle
                    required property int index
                    readonly property real angleRad: index * (360 / 24) * Math.PI / 180
                    width: index % 3 === 0 ? 8 : 5
                    height: width
                    radius: width / 2
                    color: index % 3 === 0 ? welcomeWindow.accent : index % 3 === 1 ? "#ffffff" : "#a78bfa"
                    opacity: 0
                    x: burstLayer.width / 2 - width / 2
                    y: burstLayer.height / 2 - height / 2

                    ParallelAnimation {
                        id: burstAnimP
                        NumberAnimation {
                            id: animX
                            target: particle
                            property: "x"
                            duration: 700
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            id: animY
                            target: particle
                            property: "y"
                            duration: 700
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            id: animFade
                            target: particle
                            property: "opacity"
                            to: 0
                            duration: 600
                        }
                    }

                    function fire() {
                        const dist = 110 + Math.random() * 90
                        const sx = burstLayer.width / 2 - width / 2
                        const sy = burstLayer.height / 2 - height / 2
                        x = sx
                        y = sy
                        opacity = 1
                        scale = 1
                        animX.to = sx + Math.cos(angleRad) * dist
                        animY.to = sy + Math.sin(angleRad) * dist
                        animFade.duration = 550 + Math.random() * 300
                        burstAnimP.restart()
                    }
                }
            }

            SequentialAnimation {
                id: burstAnim
                ParallelAnimation {
                    ScriptAction { script: { flash.opacity = 0.18 } }
                    NumberAnimation {
                        target: flash
                        property: "opacity"
                        to: 0
                        duration: 420
                        easing.type: Easing.OutCubic
                    }
                }
                ParallelAnimation {
                    NumberAnimation { target: ring1; properties: "scale"; from: 0.5; to: 3.6; duration: 650; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring1; property: "opacity"; from: 0.9; to: 0; duration: 650 }
                }
                ParallelAnimation {
                    NumberAnimation { target: ring2; properties: "scale"; from: 0.5; to: 3.0; duration: 620; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring2; property: "opacity"; from: 0.8; to: 0; duration: 620 }
                }
                ParallelAnimation {
                    NumberAnimation { target: ring3; properties: "scale"; from: 0.5; to: 2.5; duration: 560; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring3; property: "opacity"; from: 0.7; to: 0; duration: 560 }
                }
            }

            Connections {
                target: welcomeWindow
                function onBurstTickChanged() {
                    burstLayer.fire()
                }
            }

            function fire() {
                burstAnim.restart()
                for (let i = 0; i < particles.count; i++) {
                    const p = particles.itemAt(i)
                    if (p) p.fire()
                }
            }
        }

        // ---------- FEATURES ----------
        Item {
            id: featuresBlock
            anchors.fill: parent
            opacity: welcomeWindow.isFeatures ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity {
                NumberAnimation { duration: welcomeWindow.isFeatures ? 420 : 200; easing.type: Easing.OutCubic }
            }

            Column {
                anchors.centerIn: parent
                spacing: 18
                width: Math.min(parent.width - 90, 620)

                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Here's what Aki can do"
                        color: "white"
                        font.pixelSize: 26
                        font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Everything lives inside that little island at the top of your screen."
                        color: "#9aa0a6"
                        font.pixelSize: 13
                    }
                }

                Grid {
                    id: cardsGrid
                    width: parent.width
                    columns: 2
                    spacing: 10

                    Repeater {
                        model: [
                            { icon: "🚀", title: "App Launcher", desc: "Search & launch any app instantly.", hint: "Click the pill · SUPER+D" },
                            { icon: "🎵", title: "Media Controls", desc: "See & control what's playing.", hint: "Just hover the island" },
                            { icon: "📅", title: "Calendar", desc: "Your schedule & week at a glance.", hint: "Right-click the island" },
                            { icon: "🌐", title: "Network", desc: "Wi-Fi, VPN & connection status.", hint: "Network panel" },
                            { icon: "🔊", title: "Audio Mixer", desc: "Per-app volume & output devices.", hint: "Audio panel" },
                            { icon: "📋", title: "Clipboard History", desc: "Everything you copied, ready again.", hint: "qs ipc call island toggleClipboard" },
                            { icon: "🎬", title: "Movies & YouTube", desc: "Track shows and channel stats.", hint: "qs ipc call island toggleMovies" },
                            { icon: "🎨", title: "Live Theming", desc: "Accent color synced to your wallpaper.", hint: "Settings panel" }
                        ]
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            required property int index

                            readonly property bool revealed: welcomeWindow.svc.revealedCount > index
                            readonly property bool isLatest: welcomeWindow.svc.revealedCount === index + 1

                            width: (cardsGrid.width - cardsGrid.spacing) / 2
                            height: 76
                            radius: 14
                            color: "#141416"
                            border.width: 1
                            border.color: isLatest
                                ? welcomeWindow.accent
                                : Qt.rgba(1, 1, 1, 0.07)

                            opacity: revealed ? 1 : 0
                            transform: Translate {
                                x: card.revealed ? 0 : -18
                                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            }
                            scale: revealed ? 1 : 0.96

                            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                            Behavior on border.color { ColorAnimation { duration: 400 } }

                            Connections {
                                target: card
                                function onRevealedChanged() {
                                    if (card.revealed)
                                        Modules.FirstRunService.playSfx("reveal")
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, card.isLatest ? 0.20 : 0.10)
                                    Behavior on color { ColorAnimation { duration: 300 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: card.modelData.icon
                                        font.pixelSize: 20
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 52
                                    spacing: 2

                                    Text {
                                        text: card.modelData.title
                                        color: "white"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: card.modelData.desc
                                        color: "#9aa0a6"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: card.modelData.hint
                                        color: welcomeWindow.accent
                                        font.pixelSize: 10
                                        opacity: 0.85
                                        elide: Text.ElideMiddle
                                        width: parent.width
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "…plus notifications, a focus timer and screen-recording alerts. All built in."
                    color: "#6b7075"
                    font.pixelSize: 11
                    opacity: welcomeWindow.svc.revealedCount >= welcomeWindow.svc.totalFeatures ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 350 } }
                }

                Item {
                    width: parent.width
                    height: 54

                    Rectangle {
                        id: finishButton
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: finishRow.implicitWidth + 48
                        height: 46
                        radius: 23
                        color: finishMouse.containsMouse
                            ? Modules.ThemeService.colorWithAlpha(welcomeWindow.accent, 0.95)
                            : welcomeWindow.accent
                        scale: welcomeWindow.svc.revealedCount >= welcomeWindow.svc.totalFeatures ? 1 : 0.6
                        opacity: welcomeWindow.svc.revealedCount >= welcomeWindow.svc.totalFeatures ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Row {
                            id: finishRow
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Start exploring"
                                color: "#0a0a0c"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "✦"
                                color: "#0a0a0c"
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: finishMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Modules.FirstRunService.playSfx("press")
                                Modules.FirstRunService.finish()
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            text: "press esc to skip"
            color: "#4a4d52"
            font.pixelSize: 11
            visible: !welcomeWindow.isLeaving
        }
    }
}
