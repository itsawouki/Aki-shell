import Quickshell
import Quickshell.Io
import "." as Modules

IpcHandler {
    target: "movie"

    function toggle(): void { Modules.IslandRegistry.toggleMovieAll() }
    function open(): void { Modules.IslandRegistry.openMovieAll() }
    function close(): void { Modules.IslandRegistry.closeMovieAll() }
}
