import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "../_shared"

PluginComponent {
    id: root

    property bool cachingEnabled: pluginData.cachingEnabled ?? true

    LyricsService {
        id: lyrics
        cachingEnabled: root.cachingEnabled
    }

    // -------------------------------------------------------------------------
    // Bar Pills: show current lyric line
    // -------------------------------------------------------------------------

    horizontalBarPill: lyrics.isMusicPlayer ? hPillComponent : null

    Component {
        id: hPillComponent
        Row {
            spacing: Theme.spacingS

            Rectangle {
                width: chipContent.implicitWidth + Theme.spacingS * 2
                height: Theme.fontSizeSmall + Theme.spacingXS
                radius: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.primary

                Row {
                    id: chipContent
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: lyrics.activePlayer && lyrics.activePlayer.playbackState === MprisPlaybackState.Playing ? "lyrics" : "pause"
                        size: Theme.fontSizeSmall
                        color: Theme.background
                    }

                    StyledText {
                        text: lyrics.sourceName(lyrics.lyricSource)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.background
                        anchors.verticalCenter: parent.verticalCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        visible: lyrics.lyricsLines.length > 0
                    }
                }
            }

            StyledText {
                text: lyrics.currentLyricText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 300)
            }
        }
    }

    verticalBarPill: lyrics.isMusicPlayer ? vPillComponent : null

    Component {
        id: vPillComponent
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "lyrics"
                size: Theme.iconSize
                color: lyrics.lyricsLines.length > 0 ? Theme.primary : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: "♪"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // -------------------------------------------------------------------------
    // Popout: Lyrics Sources
    // -------------------------------------------------------------------------

    popoutContent: Component {
        PopoutComponent {
            Column {
                width: parent.width
                spacing: Theme.spacingS

                SourceCard {
                    width: parent.width
                    icon: "music_note"
                    label: "MPRIS"
                    sourceStatus: lyrics.mprisStatus
                    service: lyrics
                }

                SourceCard {
                    width: parent.width
                    icon: "cached"
                    label: "Cache"
                    sourceStatus: lyrics.cacheStatus
                    service: lyrics
                }

                SourceCard {
                    width: parent.width
                    icon: "library_music"
                    label: "lrclib"
                    sourceStatus: lyrics.lrclibStatus
                    service: lyrics
                }

                SourceCard {
                    width: parent.width
                    icon: "cloud"
                    label: "NetEase"
                    sourceStatus: lyrics.neteaseStatus
                    service: lyrics
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Reusable source status card
    // -------------------------------------------------------------------------

    component SourceCard: Rectangle {
        id: sourceCard
        property string icon: ""
        property string label: ""
        property int sourceStatus: 0
        property var service: null

        height: 44
        radius: Theme.cornerRadius
        color: sourceStatus === 0
               ? Theme.withAlpha(Theme.surfaceContainerHighest, 0.3)
               : Theme.withAlpha(service.chipColor(sourceStatus), 0.06)
        visible: true

        Row {
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.spacingM; rightMargin: Theme.spacingM
            }
            spacing: Theme.spacingS

            // Source icon
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: sourceCard.sourceStatus === 0
                       ? Theme.withAlpha(Theme.surfaceContainerHighest, 0.5)
                       : Theme.withAlpha(service.chipColor(sourceCard.sourceStatus), 0.15)
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: sourceCard.icon
                    size: 14
                    color: sourceCard.sourceStatus === 0
                           ? Theme.surfaceVariantText
                           : service.chipColor(sourceCard.sourceStatus)
                }
            }

            // Label
            StyledText {
                text: sourceCard.label
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                width: 90
            }

            // Status chip – fills remaining width
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - parent.spacing * 2 - 28 - 90
                height: 22

                Rectangle {
                    visible: sourceCard.sourceStatus !== 0
                    anchors.fill: parent
                    radius: 11
                    color: Theme.withAlpha(service.chipColor(sourceCard.sourceStatus), 0.15)

                    Row {
                        id: statusChipContent
                        anchors.centerIn: parent
                        spacing: 4

                        DankIcon {
                            name: service.chipIcon(sourceCard.sourceStatus)
                            size: 12
                            color: service.chipColor(sourceCard.sourceStatus)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: service.chipLabel(sourceCard.sourceStatus)
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: service.chipColor(sourceCard.sourceStatus)
                            anchors.verticalCenter: parent.verticalCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }
                }

                // Idle label when no status
                Rectangle {
                    visible: sourceCard.sourceStatus === 0
                    anchors.fill: parent
                    radius: 11
                    color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.3)

                    StyledText {
                        anchors.centerIn: parent
                        text: "Idle"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        maximumLineCount: 1
                    }
                }
            }
        }
    }

    popoutWidth: 340
    popoutHeight: 220

    Component.onCompleted: {
        console.info("[MusicLyrics] Plugin loaded");
    }
}
