pragma Singleton
import QtQuick

QtObject {
    id: registry

    property var islands: []

    function register(island) {
        islands.push(island)
    }

    function unregister(island) {
        const idx = islands.indexOf(island)
        if (idx !== -1) islands.splice(idx, 1)
    }

    // App launcher controls
    function toggleAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggle()
        }
    }

    function openAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].open()
        }
    }

    function closeAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].closeAll()
        }
    }

    // Music playlist selector controls
    function openMusicAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleMusic()
        }
    }

    function closeMusicAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].closeAll()
        }
    }

    function toggleMusicAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleMusic()
        }
    }

    // Power menu controls
    function openPowerAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].togglePower()
        }
    }

    function closePowerAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].closeAll()
        }
    }

    function togglePowerAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].togglePower()
        }
    }

    // Wallpaper picker controls
    function openWallpaperAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleWallpaper()
        }
    }

    function closeWallpaperAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].closeAll()
        }
    }

    function toggleWallpaperAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleWallpaper()
        }
    }

    // Movie / show picker controls
    function openMoviesAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleMovies()
        }
    }

    function closeMoviesAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].closeAll()
        }
    }

    function toggleMoviesAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleMovies()
        }
    }

    // YouTube controls
    function toggleYoutubeAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleYoutube()
        }
      }
    function toggleControlAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleControl()
        }
    }

    // Clipboard controls
    function toggleClipboardAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleClipboard()
        }
    }

    function openClipboardAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].toggleClipboard()
        }
    }

    function closeClipboardAll() {
        for (let i = 0; i < islands.length; i++) {
            if (islands[i]) islands[i].closeAll()
        }
    }
}
