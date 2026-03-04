import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "archPackageManager"

    StringSetting {
        settingKey: "preferredHelper"
        label: "Preferred AUR Helper"
        description: "Which AUR helper to use when multiple are installed. Set to 'auto' to detect automatically (prefers yay over paru), or specify 'yay' or 'paru'."
        defaultValue: "auto"
        placeholder: "auto"
    }

    StringSetting {
        settingKey: "terminal"
        label: "Terminal Emulator"
        description: "Terminal command used to launch updates. Should match the terminal configured in DMS settings (e.g., foot, kitty, alacritty -e, wezterm start --)."
        defaultValue: "foot"
        placeholder: "foot"
    }

    StringSetting {
        settingKey: "checkMethod"
        label: "Update Check Method"
        description: "How to check for updates. 'auto' prefers checkupdates for official repos (refreshes db) and AUR helper for AUR packages. 'checkupdates' same as auto but explicit. 'helper' uses the AUR helper (yay/paru -Qu) for everything without refreshing the db."
        defaultValue: "auto"
        placeholder: "auto"
    }

    StringSetting {
        settingKey: "checkInterval"
        label: "Check Interval (minutes)"
        description: "How often to check for package updates. Minimum 5 minutes. Default is 30."
        defaultValue: "30"
        placeholder: "30"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outlineVariant
    }

    ToggleSetting {
        settingKey: "showVersions"
        label: "Show Version Numbers"
        description: "Display old and new version numbers for each package in the status bar tooltip"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "notifyOnUpdates"
        label: "Show Notification on New Updates"
        description: "Display a toast notification when new updates are found"
        defaultValue: true
    }
}
