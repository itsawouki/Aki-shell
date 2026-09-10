//@ pragma UseQApplication
import Quickshell
import QtQuick
import "modules" as Modules

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Modules.DynamicIslandWindow {}
    }
    Variants {
        model: Quickshell.screens
        Modules.AudioPanelWindow {}
    }
    Variants {
        model: Quickshell.screens
        Modules.NetworkPanelWindow {}
    }
    Variants {
        model: Quickshell.screens
        Modules.SettingsPanelWindow {}
    }
    Variants {
        model: Quickshell.screens
        Modules.WelcomeWindow {}
    }
    Modules.Ipc {}
    Modules.AudioIpc {}
    Modules.NetworkIpc {}
    Modules.MusicIpc {}
    Modules.PowerIpc {}
    Modules.WallpaperIpc {}
    Modules.ClipboardIpc {}
    Modules.MovieIpc {}
    Modules.YoutubeIpc {}
    Modules.SettingsIpc {}

}
