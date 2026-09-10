import Quickshell
import Quickshell.Io
import "." as Modules

IpcHandler {
    target: "wallpaper"

    function toggle(): void { Modules.IslandRegistry.toggleWallpaperAll() }
    function open(): void { Modules.IslandRegistry.openWallpaperAll() }
    function close(): void { Modules.IslandRegistry.closeWallpaperAll() }
}
