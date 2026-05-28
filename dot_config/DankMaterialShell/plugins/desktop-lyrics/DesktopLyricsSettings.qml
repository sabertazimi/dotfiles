import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "desktop-lyrics"

    StyledText {
        width: parent.width
        text: "Desktop Lyrics Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure the desktop lyrics display appearance and behavior"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: appearanceColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: appearanceColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Appearance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            SliderSetting {
                settingKey: "backgroundOpacity"
                label: "Background Opacity"
                description: "Transparency of the lyrics overlay background (0 = fully transparent, 100 = opaque)"
                defaultValue: 85
                minimum: 0
                maximum: 100
                unit: "%"
            }

            SliderSetting {
                settingKey: "fontSize"
                label: "Font Size"
                description: "Base font size for lyrics text"
                defaultValue: 16
                minimum: 12
                maximum: 28
                unit: "px"
            }

            SelectionSetting {
                settingKey: "highlightColor"
                label: "Highlight Color"
                description: "Color used to highlight the current lyric line"
                defaultValue: "primary"
                options: [
                    { label: "Primary", value: "primary" },
                    { label: "Secondary", value: "secondary" },
                    { label: "Custom", value: "custom" }
                ]
            }

            ColorSetting {
                settingKey: "customHighlightColor"
                label: "Custom Highlight Color"
                description: "Used when highlight color is set to Custom"
                defaultValue: "#4fc3f7"
            }

            ToggleSetting {
                settingKey: "showNextLine"
                label: "Show Next Line Preview"
                description: "Display a preview of the upcoming lyric line below the current one"
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "showSourceChip"
                label: "Show Source Indicator"
                description: "Display a small chip indicating the lyrics source (lrclib, NetEase, etc.)"
                defaultValue: true
            }
        }
    }
}
