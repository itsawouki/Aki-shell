import "." as Modules
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: movieView

    property bool active: false
    signal requestClose()

    onActiveChanged: {
        if (active) {
            focusRetry.attempts = 0
            focusRetry.start()
            page = "library"
            Modules.MovieService.refresh()
        }
    }

    Timer {
        id: focusRetry
        property int attempts: 0
        interval: 30
        repeat: true
        onTriggered: {
            movieView.forceActiveFocus()
            attempts++
            if (movieView.activeFocus || attempts > 15) stop()
        }
    }

    Keys.onEscapePressed: movieView.requestClose()

    // selectedMovie is a snapshot taken when the movie was opened, not a
    // live reference into Modules.MovieService.library. Without this, any
    // mutation made while still on the seasons/episodes pages (rename
    // season, remove season, add episode, etc.) succeeds on the backend
    // but never appears on screen, because those pages keep rendering the
    // stale snapshot. Re-point selectedMovie at the fresh library entry
    // every time the library reloads, the same way the library grid
    // (cover art) always reads live data.
    Connections {
        target: Modules.MovieService
        function onLibraryChanged() {
            if (!movieView.selectedMovie) return
            var lib = Modules.MovieService.library
            for (var i = 0; i < lib.length; i++) {
                if (lib[i].title === movieView.selectedMovie.title) {
                    movieView.selectedMovie = lib[i]
                    return
                }
            }
            // The movie/show no longer exists (e.g. it was removed) — back out.
            movieView.selectedMovie = null
            movieView.page = "library"
        }
    }

    property string page: "library"
    property var selectedMovie: null
    property string selectedSeason: ""
    property string addType: "movie"
    property string newSeasonName: ""
    property var episodeRows: []
    property string editingSeason: ""
    property bool seasonEditMode: false

    onPageChanged: if (page !== "seasons") seasonEditMode = false

    function resetEpisodeRows() {
        episodeRows = [{title: "", url: ""}]
    }

    function addEpisodeRow() {
        var rows = episodeRows.slice()
        rows.push({title: "", url: ""})
        episodeRows = rows
    }

    function removeEpisodeRow(idx) {
        var rows = episodeRows.slice()
        rows.splice(idx, 1)
        if (rows.length === 0) rows.push({title: "", url: ""})
        episodeRows = rows
    }

    function updateEpisodeRow(idx, field, value) {
        if (idx < 0 || idx >= episodeRows.length) return
        var rows = episodeRows.slice()
        var row = Object.assign({}, rows[idx] ?? {})
        row[field] = value
        rows[idx] = row
        episodeRows = rows
    }

    function handleUrlPaste(text) {
        var lines = text.split("\n").filter(function(l) { return l.trim().length > 0 })
        if (lines.length <= 1) return false
        var rows = episodeRows.slice()
        for (var i = 0; i < lines.length; i++) {
            rows.push({title: "", url: lines[i].trim()})
        }
        episodeRows = rows
        return true
    }

    // TextInput is single-line, so a normal Ctrl+V paste truncates
    // multi-line clipboard content down to just the first line before
    // any QML code ever sees it. To support pasting several stream
    // links at once, we bypass TextInput's own paste handling and read
    // the clipboard ourselves via wl-paste, then split it into rows.
    property int pasteTargetRow: -1

    function pasteClipboardIntoRow(rowIndex) {
        pasteTargetRow = rowIndex
        clipboardPasteProc.running = true
    }

    Process {
        id: clipboardPasteProc
        command: ["wl-paste", "-n"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (movieView.pasteTargetRow < 0) return
                var lines = text.split("\n").map(function(l) { return l.trim() }).filter(function(l) { return l.length > 0 })
                if (lines.length === 0) { movieView.pasteTargetRow = -1; return }

                var rows = movieView.episodeRows.slice()
                var targetIdx = movieView.pasteTargetRow

                var firstRow = Object.assign({}, rows[targetIdx])
                firstRow.url = lines[0]
                rows[targetIdx] = firstRow

                var insertAt = targetIdx + 1
                for (var i = 1; i < lines.length; i++) {
                    rows.splice(insertAt, 0, {title: "", url: lines[i]})
                    insertAt++
                }

                movieView.episodeRows = rows
                movieView.pasteTargetRow = -1
            }
        }
    }

    function saveSeasonRename(newName) {
        if (!selectedMovie || newName.length === 0) return
        var oldName = editingSeason
        if (newName !== oldName) {
            Modules.MovieService.renameSeason(selectedMovie.title, oldName, newName)
            if (selectedSeason === oldName) selectedSeason = newName
        }
        editingSeason = ""
        page = "seasons"
    }

    function openMovie(movie) {
        selectedMovie = movie
        const seasonNames = Object.keys(movie.seasons ?? {})
        selectedSeason = seasonNames.length > 0 ? seasonNames[0] : ""
        seasonEditMode = false
        page = "seasons"
    }


    function playEpisode(ep) {
        Modules.MovieService.play(ep.path)
        Modules.MovieService.markWatched(ep.path)
        movieView.requestClose()
    }

    function searchAnime(query) {
        if (query.trim().length === 0) return
        Quickshell.execDetached({ command: ["kitty", "-e", "ani-cli", query] })
        movieView.requestClose()
    }

    Item {
        id: libraryPage
        anchors.fill: parent
        visible: movieView.page === "library"

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Movies & Shows"
                    color: "white"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                NavButton {
                    glyph: "+"
                    onClicked: movieView.page = "add"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                FormField {
                    id: animeSearchField
                    placeholder: "Search anime (ani-cli)…"
                    onAccepted: movieView.searchAnime(text)
                }
                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 36
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: "Search"
                        color: "white"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: movieView.searchAnime(animeSearchField.text)
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(grid.width / 4)
                cellHeight: 150
                model: Modules.MovieService.library

                delegate: Item {
                    id: cardRoot
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight

                    property bool hovered: coverArea.containsMouse || editArea.containsMouse || (removeArea && removeArea.containsMouse)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        scale: cardRoot.hovered ? 1.06 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2 }
                        }

                        Rectangle {
                            id: coverFrame
                            Layout.fillWidth: true
                            Layout.preferredHeight: 110
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.08)
                            clip: true

                            border.width: cardRoot.hovered ? 2 : 0
                            border.color: Modules.ThemeService.accentColor
                            Behavior on border.width {
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }

                            layer.enabled: cardRoot.hovered
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Modules.ThemeService.accentColor
                                shadowOpacity: 0.5
                                shadowBlur: 0.8
                            }

                            Image {
                                id: coverImg
                                anchors.fill: parent
                                source: cardRoot.modelData.cover ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready

                                scale: cardRoot.hovered ? 1.08 : 1.0
                                Behavior on scale {
                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "\u{1F3AC}"
                                font.pixelSize: 26
                                opacity: 0.35
                                visible: !coverImg.visible
                            }

                            // Full-card click-to-open sits BELOW the icon
                            // buttons in stacking order so it never steals
                            // their clicks.
                            MouseArea {
                                id: coverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: movieView.openMovie(cardRoot.modelData)
                            }

                            Rectangle {
                                id: editButton
                                width: 22; height: 22; radius: 11
                                color: Qt.rgba(0, 0, 0, 0.55)
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 4
                                visible: cardRoot.hovered

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u270E"
                                    color: "white"
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: editArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        movieView.selectedMovie = cardRoot.modelData
                                        movieView.page = "cover"
                                    }
                                }
                            }

                            Rectangle {
                                id: removeButton
                                width: 22; height: 22; radius: 11
                                color: removeArea.containsMouse ? "#ef4444" : Qt.rgba(0, 0, 0, 0.55)
                                anchors.top: parent.top
                                anchors.right: editButton.left
                                anchors.rightMargin: 4
                                anchors.topMargin: 4
                                visible: cardRoot.modelData.is_online && cardRoot.hovered
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{1F5D1}"
                                    color: "white"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: removeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Modules.MovieService.removeMovie(cardRoot.modelData.id)
                                }
                            }
                        }

                        Text {
                            text: cardRoot.modelData.title ?? ""
                            color: "white"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: !Modules.MovieService.loading && Modules.MovieService.library.length === 0
                    text: "No movies yet — tap + to add one"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: 12
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: movieView.page === "seasons" && movieView.selectedMovie !== null

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavButton {
                    glyph: "\u2039"
                    onClicked: movieView.page = "library"
                }
                Text {
                    text: movieView.selectedMovie?.title ?? ""
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Rectangle {
                    visible: (movieView.selectedMovie?.is_online ?? false)
                                    && Object.keys(movieView.selectedMovie.seasons ?? {}).length > 0
                    width: 26; height: 26; radius: 8
                    color: movieView.seasonEditMode ? Modules.ThemeService.accentColor
                        : (seasonEditModeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08))
                    Text {
                        anchors.centerIn: parent
                        text: "\u270E"
                        color: movieView.seasonEditMode ? "#0b0b0e" : "white"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: seasonEditModeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: movieView.seasonEditMode = !movieView.seasonEditMode
                    }
                }
            }

            Flow {
                id: seasonsFlow
                Layout.fillWidth: true
                spacing: 6
                visible: movieView.selectedMovie
                    ? Object.keys(movieView.selectedMovie.seasons ?? {}).length > 0
                    : false

                Repeater {
                    model: movieView.selectedMovie ? Object.keys(movieView.selectedMovie.seasons ?? {}) : []
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool chipEditing: movieView.seasonEditMode
                            && (movieView.selectedMovie?.is_online ?? false)
                        radius: 8
                        height: 26
                        width: Math.min(seasonLabel.implicitWidth + (chipEditing ? 42 : 20), seasonsFlow.width - 12)
                        color: movieView.selectedSeason === modelData ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.08)

                        // Declared first so the edit/delete buttons below it
                        // stack on top and receive their own clicks.
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: movieView.selectedSeason = parent.modelData
                        }

                        Text {
                            id: seasonLabel
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            width: parent.width - (chipEditing ? 52 : 20)
                            elide: Text.ElideRight
                            text: parent.modelData
                            color: movieView.selectedSeason === parent.modelData ? "#0b0b0e" : "white"
                            font.pixelSize: 11
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            spacing: 2
                            visible: chipEditing

                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: seasonEditArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.1)
                                Text { anchors.centerIn: parent; text: "\u270E"; color: "white"; font.pixelSize: 9 }
                                MouseArea {
                                    id: seasonEditArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        movieView.editingSeason = modelData
                                        movieView.page = "renameSeason"
                                    }
                                }
                            }
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: seasonDelArea.containsMouse ? "#ef4444" : Qt.rgba(1, 1, 1, 0.1)
                                Text { anchors.centerIn: parent; text: "\u{1F5D1}"; color: "white"; font.pixelSize: 8 }
                                MouseArea {
                                    id: seasonDelArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Modules.MovieService.removeSeason(movieView.selectedMovie.title, modelData)
                                        var keys = Object.keys(movieView.selectedMovie.seasons ?? {})
                                        var idx = keys.indexOf(modelData)
                                        keys.splice(idx, 1)
                                        movieView.selectedSeason = keys.length > 0 ? keys[0] : ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: {
                    if (!movieView.selectedMovie) return []
                    return movieView.selectedMovie.seasons?.[movieView.selectedSeason] ?? []
                }

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 48
                    radius: 10
                    clip: true

                    color: modelData.watched
                        ? (rowHover.hovered ? Qt.rgba(0.29, 0.87, 0.50, 0.22) : Qt.rgba(0.29, 0.87, 0.50, 0.14))
                        : (rowHover.hovered ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
                    Behavior on color { ColorAnimation { duration: 140 } }

                    HoverHandler {
                        id: rowHover
                    }

                    // Solid accent bar down the left edge — much harder to
                    // miss than a faint background tint alone.
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 4
                        color: "#4ade80"
                        visible: modelData.watched
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: modelData.watched ? 18 : 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        spacing: 10
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 140 } }

                        Text {
                            text: modelData.watched ? "\u2713" : "\u25B6"
                            color: modelData.watched ? "#4ade80" : Qt.rgba(1, 1, 1, 0.6)
                            font.pixelSize: 13
                        }

                        Text {
                            text: modelData.title
                            color: "white"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            visible: modelData.watched
                            Layout.preferredWidth: watchedLabel.implicitWidth + 12
                            Layout.preferredHeight: 18
                            radius: 9
                            color: Qt.rgba(0.29, 0.87, 0.50, 0.25)

                            Text {
                                id: watchedLabel
                                anchors.centerIn: parent
                                text: "WATCHED"
                                color: "#4ade80"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: Qt.rgba(1, 1, 1, 0.08)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.watched ? "\u21BA" : "\u2713"
                                color: "white"
                                font.pixelSize: 10
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Modules.MovieService.toggleWatched(modelData.path)
                            }
                        }

                        Rectangle {
                            visible: movieView.selectedMovie?.is_online ?? false
                            width: 22; height: 22; radius: 11
                            color: epRemoveArea.containsMouse ? "#ef4444" : Qt.rgba(1, 1, 1, 0.08)
                            Text {
                                anchors.centerIn: parent
                                text: "\u{1F5D1}"
                                color: "white"
                                font.pixelSize: 10
                            }
                            MouseArea {
                                id: epRemoveArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Modules.MovieService.removeEpisode(movieView.selectedMovie.id, modelData.path)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: movieView.playEpisode(parent.modelData)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                visible: movieView.selectedMovie?.is_online ?? false
                Text {
                    anchors.centerIn: parent
                    text: "+ Add online link as episode"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        movieView.resetEpisodeRows()
                        movieView.page = "addEpisode"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                visible: movieView.selectedMovie?.is_online ?? false
                Text {
                    anchors.centerIn: parent
                    text: "+ Add new season"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: movieView.page = "addSeason"
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: movieView.page === "add"

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavButton {
                    glyph: "\u2039"
                    onClicked: movieView.page = "library"
                }
                Text {
                    text: "Add movie / show"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: movieView.addType === "movie" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: "Movie"
                        color: movieView.addType === "movie" ? "#0b0b0e" : Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: movieView.addType = "movie"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: movieView.addType === "show" ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: "TV Show"
                        color: movieView.addType === "show" ? "#0b0b0e" : Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: movieView.addType = "show"
                    }
                }
            }

            FormField { id: addTitleField; placeholder: "Title" }
            FormField { id: addUrlField; placeholder: "Stream URL"; visible: movieView.addType === "movie" }
            FormField { id: addCoverField; placeholder: "Cover image URL (optional)" }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: Modules.ThemeService.accentColor
                Text {
                    anchors.centerIn: parent
                    text: movieView.addType === "movie" ? "Add movie" : "Add show"
                    color: "#0b0b0e"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (addTitleField.text.length === 0) return
                        if (movieView.addType === "movie") {
                            if (addUrlField.text.length === 0) return
                            Modules.MovieService.addOnlineMovie(addTitleField.text, addUrlField.text, addCoverField.text)
                        } else {
                            Modules.MovieService.addShow(addTitleField.text, addCoverField.text)
                        }
                        addTitleField.text = ""; addUrlField.text = ""; addCoverField.text = ""
                        movieView.addType = "movie"
                        movieView.page = "library"
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: movieView.page === "addEpisode"

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavButton {
                    glyph: "\u2039"
                    onClicked: movieView.page = "seasons"
                }
                Text {
                    text: "Add episodes"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            Flow {
                id: seasonPickFlow
                Layout.fillWidth: true
                spacing: 6
                visible: movieView.selectedMovie
                    ? Object.keys(movieView.selectedMovie.seasons ?? {}).length > 0
                    : false

                Repeater {
                    model: movieView.selectedMovie ? Object.keys(movieView.selectedMovie.seasons ?? {}) : []
                    delegate: Rectangle {
                        required property string modelData
                        radius: 8
                        height: 26
                        width: Math.min(seasonPickLabel.implicitWidth + 20, seasonPickFlow.width - 12)
                        color: movieView.selectedSeason === modelData ? Modules.ThemeService.accentColor : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: seasonPickLabel
                            anchors.centerIn: parent
                            width: parent.width - 12
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData
                            color: movieView.selectedSeason === parent.modelData ? "#0b0b0e" : "white"
                            font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: movieView.selectedSeason = parent.modelData
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.06)
                Text {
                    anchors.centerIn: parent
                    text: "Tip: copy several links, then Ctrl+V (or tap \u{1F4CB}) in a URL field to add one row per link"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: 10
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: movieView.episodeRows.length

                delegate: Rectangle {
                    id: epRowRoot
                    required property int index
                    width: ListView.view.width
                    height: 70
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.04)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "#" + (epRowRoot.index + 1)
                                color: Qt.rgba(1, 1, 1, 0.3)
                                font.pixelSize: 10
                                Layout.preferredWidth: 24
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.06)
                                TextInput {
                                    id: titleInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    color: "white"
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                    clip: true
                                    text: movieView.episodeRows[epRowRoot.index]?.title ?? ""
                                    onTextChanged: movieView.updateEpisodeRow(epRowRoot.index, "title", text)
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Episode title (optional)"
                                    color: Qt.rgba(1, 1, 1, 0.35)
                                    font.pixelSize: 11
                                    visible: titleInput.text.length === 0
                                }
                            }

                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: rowDelArea.containsMouse ? "#ef4444" : Qt.rgba(1, 1, 1, 0.1)
                                visible: movieView.episodeRows.length > 1
                                Text { anchors.centerIn: parent; text: "\u2715"; color: "white"; font.pixelSize: 9 }
                                MouseArea {
                                    id: rowDelArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: movieView.removeEpisodeRow(epRowRoot.index)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.06)
                                TextInput {
                                    id: urlInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    color: "white"
                                    font.pixelSize: 11
                                    verticalAlignment: Text.AlignVCenter
                                    clip: true
                                    text: movieView.episodeRows[epRowRoot.index]?.url ?? ""
                                    onTextChanged: {
                                        if (!movieView.handleUrlPaste(text)) {
                                            movieView.updateEpisodeRow(epRowRoot.index, "url", text)
                                        }
                                    }
                                    // TextInput truncates multi-line clipboard
                                    // content to one line before we ever see
                                    // it, so intercept Ctrl+V ourselves and
                                    // read the clipboard directly.
                                    Keys.onPressed: (event) => {
                                        if (event.matches(StandardKey.Paste)) {
                                            event.accepted = true
                                            movieView.pasteClipboardIntoRow(epRowRoot.index)
                                        }
                                    }
                                }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Stream URL"
                                    color: Qt.rgba(1, 1, 1, 0.35)
                                    font.pixelSize: 11
                                    visible: urlInput.text.length === 0
                                }
                            }

                            Rectangle {
                                width: 26; height: 26; radius: 8
                                color: pasteArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{1F4CB}"
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    id: pasteArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: movieView.pasteClipboardIntoRow(epRowRoot.index)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                Text {
                    anchors.centerIn: parent
                    text: "+ Add another episode"
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: movieView.addEpisodeRow()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: Modules.ThemeService.accentColor
                Text {
                    anchors.centerIn: parent
                    text: "Add all episodes"
                    color: "#0b0b0e"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!movieView.selectedMovie) return
                        var eps = []
                        for (var i = 0; i < movieView.episodeRows.length; i++) {
                            var row = movieView.episodeRows[i] ?? {}
                            var url = String(row.url ?? "").trim()
                            if (url.length === 0) continue
                            var t = String(row.title ?? "").trim()
                            eps.push({ title: t.length > 0 ? t : "Episode " + (i + 1), url: url })
                        }
                        if (eps.length > 0) {
                            console.log("[MovieView] bulk adding", eps.length, "episodes to", movieView.selectedMovie.title)
                            Modules.MovieService.addOnlineEpisodes(movieView.selectedMovie.title, movieView.selectedSeason, eps)
                            movieView.resetEpisodeRows()
                            movieView.page = "seasons"
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: movieView.page === "addSeason"

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavButton {
                    glyph: "\u2039"
                    onClicked: movieView.page = "seasons"
                }
                Text {
                    text: "Add season"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            FormField { id: seasonNameField; placeholder: "Season name (e.g. Season 1)" }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: Modules.ThemeService.accentColor
                Text {
                    anchors.centerIn: parent
                    text: "Add season"
                    color: "#0b0b0e"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!movieView.selectedMovie || seasonNameField.text.length === 0) return
                        Modules.MovieService.addSeason(movieView.selectedMovie.title, seasonNameField.text)
                        movieView.selectedSeason = seasonNameField.text
                        seasonNameField.text = ""
                        movieView.page = "seasons"
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: movieView.page === "renameSeason"

        onVisibleChanged: {
            if (visible) renameSeasonField.text = movieView.editingSeason
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavButton {
                    glyph: "\u2039"
                    onClicked: {
                        movieView.editingSeason = ""
                        movieView.page = "seasons"
                    }
                }
                Text {
                    text: "Rename season"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
            }

            FormField {
                id: renameSeasonField
                placeholder: "Season name"
                onAccepted: movieView.saveSeasonRename(renameSeasonField.text)
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: Modules.ThemeService.accentColor
                Text {
                    anchors.centerIn: parent
                    text: "Save name"
                    color: "#0b0b0e"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: movieView.saveSeasonRename(renameSeasonField.text)
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: movieView.page === "cover"

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavButton {
                    glyph: "\u2039"
                    onClicked: movieView.page = "library"
                }
                Text {
                    text: "Set cover — " + (movieView.selectedMovie?.title ?? "")
                    color: "white"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            FormField { id: coverUrlField; placeholder: "Image path or URL" }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: Modules.ThemeService.accentColor
                Text {
                    anchors.centerIn: parent
                    text: "Save cover"
                    color: "#0b0b0e"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!movieView.selectedMovie || coverUrlField.text.length === 0) return
                        Modules.MovieService.setCover(movieView.selectedMovie.title, coverUrlField.text)
                        coverUrlField.text = ""
                        movieView.page = "library"
                    }
                }
            }
        }
    }
}
