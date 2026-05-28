import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "../_shared"

DesktopPluginComponent {
    id: root

    minWidth: 400
    minHeight: 40

    property real backgroundOpacity: (pluginData.backgroundOpacity ?? 85) / 100
    property real fontSize: pluginData.fontSize ?? 16
    property string highlightColor: pluginData.highlightColor ?? "primary"
    property color customHighlightColor: pluginData.customHighlightColor ?? "#4fc3f7"
    property bool showNextLine: pluginData.showNextLine ?? true
    property bool showSourceChip: pluginData.showSourceChip ?? true

    readonly property color accentColor: {
        if (highlightColor === "secondary") return Theme.secondary;
        if (highlightColor === "custom") return customHighlightColor;
        return Theme.primary;
    }

    LyricsService {
        id: lyrics
        cachingEnabled: true
    }

    readonly property bool hasLyrics: lyrics.lyricsLines.length > 0 && lyrics.currentLineIndex >= 0
    readonly property bool isPlaying: lyrics.activePlayer
        && lyrics.activePlayer.playbackState === MprisPlaybackState.Playing

    visible: isPlaying && lyrics.isMusicPlayer

    // Auto-size height based on content
    onHasLyricsChanged: _updateMinHeight()
    onShowNextLineChanged: _updateMinHeight()

    function _updateMinHeight() {
        minHeight = hasLyrics ? (showNextLine ? 56 : 36) : 36;
    }

    // -------------------------------------------------------------------------
    // Background pill
    // -------------------------------------------------------------------------

    Rectangle {
        id: bgPill
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, backgroundOpacity)

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.4
            blurMax: 32
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2
            shadowBlur: 0.6
            shadowColor: Theme.shadowMedium
            shadowOpacity: 0.3
        }
    }

    // -------------------------------------------------------------------------
    // Content overlay
    // -------------------------------------------------------------------------

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingS

        // Source chip
        Rectangle {
            visible: root.showSourceChip && root.hasLyrics && lyrics.lyricSource !== lyrics.srcNone
            width: visible ? sourceChipRow.implicitWidth + Theme.spacingS * 2 : 0
            height: root.fontSize
            radius: height / 2
            color: Theme.withAlpha(root.accentColor, 0.15)
            Layout.alignment: Qt.AlignVCenter

            Row {
                id: sourceChipRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    name: "lyrics"
                    size: root.fontSize - 4
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: lyrics.sourceName(lyrics.lyricSource)
                    font.pixelSize: root.fontSize - 4
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Lyrics text area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Current line
            StyledText {
                id: currentLine
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.hasLyrics
                    ? lyrics.currentLyricText
                    : (lyrics.lyricsLoading
                        ? "Searching lyrics…"
                        : (lyrics.currentTitle
                            ? lyrics.currentTitle
                            : "No music playing"))
                font.pixelSize: root.fontSize
                font.weight: Font.Bold
                color: root.hasLyrics ? root.accentColor : Theme.surfaceText
                elide: Text.ElideRight
                maximumLineCount: 1

                layer.enabled: root.hasLyrics
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 1
                    shadowBlur: 0.5
                    shadowColor: root.accentColor
                    shadowOpacity: 0.25
                }
            }

            // Next line preview
            StyledText {
                id: nextLine
                Layout.fillWidth: true
                visible: root.showNextLine && root.hasLyrics && lyrics.nextLyricText.length > 0
                text: lyrics.nextLyricText
                font.pixelSize: root.fontSize - 2
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.7
            }
        }
    }

    Component.onCompleted: {
        console.info("[DesktopLyrics] Plugin loaded");
        _updateMinHeight();
    }
}
