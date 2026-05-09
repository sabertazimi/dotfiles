import Quickshell
import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "music-lyrics"

    StyledText {
        width: parent.width
        text: "Music Lyrics Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure lyrics sources and behavior"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: durationsColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: durationsColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Cache"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            ToggleSetting {
                settingKey: "cachingEnabled"
                label: "Local Cache"
                description: "Save downloaded lyrics locally to speed up loading times and reduce network requests. Lyrics files will be stored under ~/.cache/music-lyrics directory."
                defaultValue: true
            }
        }
    }

    StyledRect {
        width: parent.width
        height: behaviorColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: behaviorColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Navidrome"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StringSetting {
                settingKey: "navidromeUrl"
                label: "Server URL"
                description: "The full address of your instance."
                placeholder: "https://music.example.com:4533"
                defaultValue: ""
            }

            StringSetting {
                settingKey: "navidromeUser"
                label: "Username"
                placeholder: "username"
                defaultValue: ""
            }

            StringSetting {
                settingKey: "navidromePassword"
                label: "Password"
                placeholder: "password"
                defaultValue: ""
            }
        }
    }
}
