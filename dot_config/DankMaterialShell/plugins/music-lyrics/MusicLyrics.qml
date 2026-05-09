import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool cachingEnabled: pluginData.cachingEnabled ?? true

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    property var allPlayers: MprisController.availablePlayers

    // -------------------------------------------------------------------------
    // Enum namespaces
    // -------------------------------------------------------------------------

    // Chip-visible statuses
    // Values are globally unique so all status properties share one _chipMeta map
    QtObject {
        id: status
        readonly property int none: 0
        readonly property int searching: 1
        readonly property int found: 2
        readonly property int notFound: 3
        readonly property int error: 4
        readonly property int skippedFound: 5
        readonly property int skippedPlain: 6
        readonly property int cacheHit: 11
        readonly property int cacheMiss: 12
        readonly property int cacheDisabled: 13
    }

    // Lyrics-fetch lifecycle
    QtObject {
        id: lyricState
        readonly property int idle: 0
        readonly property int loading: 1
        readonly property int synced: 2
        readonly property int notFound: 3
    }

    // Lyrics sources
    QtObject {
        id: lyricSrc
        readonly property int none: 0
        readonly property int mpris: 1
        readonly property int cache: 2
        readonly property int lrclib: 3
        readonly property int netease: 4
    }

    // -------------------------------------------------------------------------
    // Lyrics state
    // -------------------------------------------------------------------------

    property var lyricsLines: []
    property int currentLineIndex: -1
    property bool lyricsLoading: lyricStatus === lyricState.loading
    property string _lastFetchedTrack: ""
    property string _lastFetchedArtist: ""
    property var _cancelActiveFetch: null

    // Chip status properties
    property int mprisStatus: status.none
    property int cacheStatus: status.none
    property int lrclibStatus: status.none
    property int neteaseStatus: status.none

    // Fetch state and source
    property int lyricStatus: lyricState.idle
    property int lyricSource: lyricSrc.none

    // Track current song info
    property string currentTitle: activePlayer?.trackTitle ?? ""
    property string currentArtist: activePlayer?.trackArtist ?? ""
    property string currentAlbum: activePlayer?.trackAlbum ?? ""
    property real currentDuration: activePlayer?.length ?? 0

    // -------------------------------------------------------------------------
    // Music player detection
    // -------------------------------------------------------------------------

    readonly property var _musicPlayerPatterns: [
        "apple music", "spotify", "netease", "qqmusic",
        "rhythmbox", "mpd", "navidrome",
        "musicfox", "cmus", "ncmpcpp"
    ]

    readonly property var _nonMusicPlayerPatterns: [
        "firefox", "chrome", "chromium",
        "vlc", "mpv", "jellyfin"
    ]

    readonly property bool _isMusicPlayer: {
        if (!activePlayer) return false;
        var identity = (activePlayer.identity || "").toLowerCase();
        for (var i = 0; i < _musicPlayerPatterns.length; i++) {
            if (identity.indexOf(_musicPlayerPatterns[i]) !== -1)
                return true;
        }
        for (var i = 0; i < _nonMusicPlayerPatterns.length; i++) {
            if (identity.indexOf(_nonMusicPlayerPatterns[i]) !== -1)
                return false;
        }
        return (activePlayer.trackArtist || "").length > 0;
    }

    on_IsMusicPlayerChanged: {
        if (_isMusicPlayer && currentTitle)
            fetchDebounceTimer.restart();
    }

    // Current lyric line for bar pill display
    property string currentLyricText: {
        if (lyricsLoading)
            return "Searching lyrics…";
        if (lyricsLines.length > 0 && currentLineIndex >= 0)
            return lyricsLines[currentLineIndex].text || "♪ ♪ ♪";
        if (currentTitle)
            return currentTitle;
        return "No lyrics";
    }

    // Debounce timer — avoids double-fetch when title and artist change simultaneously
    Timer {
        id: fetchDebounceTimer
        interval: 300
        onTriggered: root.fetchLyricsIfNeeded()
    }
    onCurrentTitleChanged: fetchDebounceTimer.restart()
    onCurrentArtistChanged: fetchDebounceTimer.restart()

    // Force-update toggle to poll MPRIS position
    property bool _forceUpdate: false

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _resetLyricsState() {
        lyricsLines = [];
        currentLineIndex = -1;
        mprisStatus = status.none;
        cacheStatus = status.none;
        lrclibStatus = status.none;
        neteaseStatus = status.none;
        lyricStatus = lyricState.loading;
        lyricSource = lyricSrc.none;
    }

    // lrclib fail → NetEase
    function _setLrclibNotFound(lrclibStatusVal) {
        lrclibStatus = lrclibStatusVal;
        _fetchFromNetease(_lastFetchedTrack, _lastFetchedArtist);
    }

    // NetEase fail → final (all sources exhausted)
    function _setNeteaseNotFound(neteaseStatusVal) {
        neteaseStatus = neteaseStatusVal;
        lyricStatus = lyricState.notFound;
        root._cancelActiveFetch = null;
    }

    // -------------------------------------------------------------------------
    // Cache helpers
    // -------------------------------------------------------------------------

    function _fnv1a32(str) {
        var hash = 0x811c9dc5;
        for (var i = 0; i < str.length; i++) {
            hash = ((hash ^ str.charCodeAt(i)) * 0x01000193) >>> 0;
        }
        return ("00000000" + hash.toString(16)).slice(-8);
    }

    function _cacheKey(title, artist) {
        return _fnv1a32((title + "\x00" + artist).toLowerCase());
    }

    readonly property string _cacheDir: (Quickshell.env("HOME") || "") + "/.cache/music-lyrics"

    function _cacheFilePath(title, artist) {
        return _cacheDir + "/" + _cacheKey(title, artist) + ".json";
    }

    // Static one-shot timer for XHR request timeouts
    Timer {
        id: xhrTimeoutTimer
        repeat: false
        property var onTimeout: null
        onTriggered: if (onTimeout)
            onTimeout()
    }

    // Static one-shot timer for retry delays
    Timer {
        id: xhrRetryTimer
        repeat: false
        property var onRetry: null
        onTriggered: if (onRetry)
            onRetry()
    }

    // Cache directory creation
    property bool _cacheDirReady: false

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", root._cacheDir]
        running: false
    }

    function _ensureCacheDir() {
        if (_cacheDirReady)
            return;
        _cacheDirReady = true;
        mkdirProcess.running = true;
    }

    // Cache read using FileView
    Component {
        id: cacheReaderComponent
        FileView {
            property var callback
            blockLoading: true
            preload: true
            onLoaded: {
                try {
                    callback(JSON.parse(text()));
                } catch (e) {
                    callback(null);
                }
                destroy();
            }
            onLoadFailed: {
                callback(null);
                destroy();
            }
        }
    }

    function readFromCache(title, artist, callback) {
        cacheReaderComponent.createObject(root, {
            path: _cacheFilePath(title, artist),
            callback: callback
        });
    }

    // Cache write using FileView
    Component {
        id: cacheWriterComponent
        FileView {
            property string cTitle
            property string cArtist
            blockWrites: false
            atomicWrites: true
            onSaved: {
                console.info("[MusicLyrics] Cache: written for \"" + cTitle + "\" by " + cArtist + " (" + path + ")");
                destroy();
            }
            onSaveFailed: {
                console.warn("[MusicLyrics] Cache: failed to write for \"" + cTitle + "\"");
                destroy();
            }
        }
    }

    function writeToCache(title, artist, lines, source) {
        _ensureCacheDir();
        var writer = cacheWriterComponent.createObject(root, {
            path: _cacheFilePath(title, artist),
            cTitle: title,
            cArtist: artist
        });
        writer.setText(JSON.stringify({
            lines: lines,
            source: source
        }));
    }

    // -------------------------------------------------------------------------
    // Fetch orchestration
    // -------------------------------------------------------------------------

    function fetchLyricsIfNeeded() {
        if (!_isMusicPlayer)
            return;
        if (!currentTitle)
            return;
        if (currentTitle === _lastFetchedTrack && currentArtist === _lastFetchedArtist)
            return;

        // Cancel any in-flight XHR before starting fresh
        if (_cancelActiveFetch) {
            _cancelActiveFetch();
            _cancelActiveFetch = null;
        }

        _lastFetchedTrack = currentTitle;
        _lastFetchedArtist = currentArtist;
        _resetLyricsState();

        var durationStr = currentDuration > 0 ? (Math.floor(currentDuration / 60) + ":" + ("0" + Math.floor(currentDuration % 60)).slice(-2)) : "unknown";
        console.info("[MusicLyrics] ▶ Track changed: \"" + currentTitle + "\" by " + currentArtist + (currentAlbum ? " [" + currentAlbum + "]" : "") + " (" + durationStr + ")");

        var capturedTitle = currentTitle;
        var capturedArtist = currentArtist;

        // 1. Try MPRIS metadata first (instant, no network)
        var mprisLyricsText = "";
        if (activePlayer && activePlayer.metadata) {
            mprisLyricsText = activePlayer.metadata["xesam:asText"] || "";
        }
        if (mprisLyricsText.length > 0) {
            var mprisLines = parseLrc(mprisLyricsText);
            if (mprisLines.length > 0) {
                lyricsLines = mprisLines;
                mprisStatus = status.found;
                lyricStatus = lyricState.synced;
                lyricSource = lyricSrc.mpris;
                cacheStatus = status.skippedFound;
                lrclibStatus = status.skippedFound;
                neteaseStatus = status.skippedFound;
                console.info("[MusicLyrics] ✓ MPRIS: synced lyrics found (" + mprisLines.length + " lines) for \"" + currentTitle + "\"");
                return;
            }
            mprisStatus = status.skippedPlain;
            console.info("[MusicLyrics] ✗ MPRIS: only plain lyrics found (skipping, synced only)");
        } else {
            mprisStatus = status.notFound;
        }

        // 2. Cache / API fallback
        function _startFetch() {
            _fetchFromLrclib(capturedTitle, capturedArtist);
        }

        if (cachingEnabled) {
            readFromCache(capturedTitle, capturedArtist, function (cached) {
                // Guard: track may have changed while the file read was in progress
                if (capturedTitle !== root._lastFetchedTrack || capturedArtist !== root._lastFetchedArtist)
                    return;
                if (cached && cached.lines && cached.lines.length > 0) {
                    root.lyricsLines = cached.lines;
                    root.lyricStatus = lyricState.synced;
                    root.lyricSource = cached.source > 0 ? cached.source : lyricSrc.cache;
                    root.cacheStatus = status.cacheHit;
                    root.lrclibStatus = status.skippedFound;
                    root.neteaseStatus = status.skippedFound;
                    console.info("[MusicLyrics] ✓ Cache: lyrics loaded for \"" + capturedTitle + "\" (" + cached.lines.length + " lines)");
                    return;
                }
                root.cacheStatus = status.cacheMiss;
                _startFetch();
            });
        } else {
            cacheStatus = status.cacheDisabled;
            _startFetch();
        }
    }

    // -------------------------------------------------------------------------
    // XMLHttpRequest helper
    // -------------------------------------------------------------------------

    function _xhrGet(url, timeoutMs, onSuccess, onError, customHeaders) {
        var retriesLeft = 2;
        var retryDelay = 3000;
        var attempt = 0;
        var cancelled = false;
        var currentXhr = null;

        function _attempt() {
            attempt++;
            currentXhr = new XMLHttpRequest();
            var done = false;

            xhrTimeoutTimer.stop();
            xhrTimeoutTimer.interval = timeoutMs;
            xhrTimeoutTimer.onTimeout = function () {
                if (!done && !cancelled) {
                    done = true;
                    currentXhr.abort();
                    _retry("timeout");
                }
            };
            xhrTimeoutTimer.start();

            currentXhr.onreadystatechange = function () {
                if (currentXhr.readyState !== XMLHttpRequest.DONE || done || cancelled)
                    return;
                done = true;
                xhrTimeoutTimer.stop();
                if (currentXhr.status === 0) {
                    _retry("network error (status 0)");
                    return;
                }
                var responseBody = (currentXhr.responseText || "").trim();
                if (responseBody.length === 0) {
                    _retry("empty response (HTTP " + currentXhr.status + ")");
                    return;
                }
                onSuccess(currentXhr.responseText, currentXhr.status);
            };
            currentXhr.open("GET", url);
            if (customHeaders) {
                for (var key in customHeaders)
                    currentXhr.setRequestHeader(key, customHeaders[key]);
            } else {
                currentXhr.setRequestHeader("User-Agent", "DankMaterialShell MusicLyrics/1.4.0 (https://github.com/Gasiyu/dms-plugin-musiclyrics)");
                currentXhr.setRequestHeader("Accept", "application/json");
            }
            currentXhr.send();
        }

        function _retry(errMsg) {
            if (cancelled)
                return;
            if (retriesLeft > 0) {
                retriesLeft--;
                console.warn("[MusicLyrics] _xhrGet: " + errMsg + " — retrying (attempt " + (attempt + 1) + ", " + retriesLeft + " left): " + url);
                xhrRetryTimer.stop();
                xhrRetryTimer.interval = retryDelay;
                xhrRetryTimer.onRetry = _attempt;
                xhrRetryTimer.start();
            } else {
                onError(errMsg);
            }
        }

        _attempt();

        // Return a cancel function the caller can invoke to abort the entire chain
        return function cancel() {
            cancelled = true;
            xhrTimeoutTimer.stop();
            xhrRetryTimer.stop();
            if (currentXhr)
                currentXhr.abort();
            console.info("[MusicLyrics] ⊘ XHR cancelled: " + url);
        };
    }

    // -------------------------------------------------------------------------
    // lrclib.net fetch
    // -------------------------------------------------------------------------

    function _fetchFromLrclib(expectedTitle, expectedArtist) {
        if (lyricStatus === lyricState.synced) {
            lrclibStatus = status.skippedFound;
            console.info("[MusicLyrics] lrclib: skipped (synced lyrics already found)");
            return;
        }

        lrclibStatus = status.searching;
        console.info("[MusicLyrics] lrclib: searching for \"" + expectedTitle + "\" by " + expectedArtist);

        var url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(expectedArtist) + "&track_name=" + encodeURIComponent(expectedTitle);
        if (currentAlbum)
            url += "&album_name=" + encodeURIComponent(currentAlbum);
        if (currentDuration > 0)
            url += "&duration=" + Math.round(currentDuration);

        root._cancelActiveFetch = _xhrGet(url, 20000, function (responseText, httpStatus) {
            var rawData = (responseText || "").trim();
            console.log("[MusicLyrics] lrclib: response length = " + rawData.length);
            if (rawData.length === 0) {
                root._setLrclibNotFound(status.error);
                console.warn("[MusicLyrics] lrclib: empty response (HTTP " + httpStatus + ")");
                return;
            }
            try {
                var result = JSON.parse(rawData);
                if (result.statusCode === 404 || result.error) {
                    root._setLrclibNotFound(status.notFound);
                    console.info("[MusicLyrics] ✗ lrclib: no lyrics found for \"" + expectedTitle + "\"");
                } else if (result.syncedLyrics) {
                    root.lyricsLines = root.parseLrc(result.syncedLyrics);
                    root.lrclibStatus = status.found;
                    root.neteaseStatus = status.skippedFound;
                    root.lyricStatus = lyricState.synced;
                    root.lyricSource = lyricSrc.lrclib;
                    console.info("[MusicLyrics] ✓ lrclib: synced lyrics found (" + root.lyricsLines.length + " lines) for \"" + expectedTitle + "\"");
                    root._cancelActiveFetch = null;
                    if (root.cachingEnabled)
                        root.writeToCache(expectedTitle, expectedArtist, root.lyricsLines, lyricSrc.lrclib);
                } else if (result.plainLyrics) {
                    root._setLrclibNotFound(status.skippedPlain);
                    console.info("[MusicLyrics] ✗ lrclib: only plain lyrics found for \"" + expectedTitle + "\" (skipping, synced only)");
                } else {
                    root._setLrclibNotFound(status.notFound);
                    console.info("[MusicLyrics] ✗ lrclib: response contained no lyrics for \"" + expectedTitle + "\"");
                }
            } catch (e) {
                root._setLrclibNotFound(status.error);
                console.warn("[MusicLyrics] lrclib: failed to parse response — " + e);
                console.warn("[MusicLyrics] lrclib: raw data: " + rawData.substring(0, 200));
            }
        }, function (errMsg) {
            root._setLrclibNotFound(status.error);
            console.warn("[MusicLyrics] lrclib: request failed — " + errMsg);
        });
    }

    // -------------------------------------------------------------------------
    // NetEase Cloud Music fetch (网易云音乐)
    // -------------------------------------------------------------------------

    function _neteaseHeaders() {
        return {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
            "Accept": "application/json",
            "Referer": "https://music.163.com/",
            "Cookie": "appver=2.0.2"
        };
    }

    function _fetchFromNetease(expectedTitle, expectedArtist) {
        if (lyricStatus === lyricState.synced) {
            neteaseStatus = status.skippedFound;
            console.info("[MusicLyrics] NetEase: skipped (synced lyrics already found)");
            return;
        }

        neteaseStatus = status.searching;
        console.info("[MusicLyrics] NetEase: searching for \"" + expectedTitle + "\" by " + expectedArtist);

        var keyword = expectedTitle + " " + expectedArtist;
        var searchUrl = "https://music.163.com/api/search/get?s=" + encodeURIComponent(keyword)
            + "&type=1&offset=0&total=true&limit=20";

        root._cancelActiveFetch = _xhrGet(searchUrl, 15000, function (responseText, httpStatus) {
            if (expectedTitle !== root._lastFetchedTrack || expectedArtist !== root._lastFetchedArtist)
                return;

            try {
                var result = JSON.parse(responseText);
                if (result.code !== 200 || !result.result || !result.result.songs || result.result.songs.length === 0) {
                    root._setNeteaseNotFound(status.notFound);
                    console.info("[MusicLyrics] ✗ NetEase: no search results for \"" + expectedTitle + "\"");
                    return;
                }

                var songs = result.result.songs;
                var lowerTitle = expectedTitle.toLowerCase();
                var bestSong = null;

                for (var i = 0; i < songs.length; i++) {
                    if ((songs[i].name || "").toLowerCase() === lowerTitle) {
                        bestSong = songs[i];
                        break;
                    }
                }
                if (!bestSong)
                    bestSong = songs[0];

                var songId = bestSong.id;
                var artistName = bestSong.artists
                    ? bestSong.artists.map(function (a) { return a.name || ""; }).join("/")
                    : "";
                console.info("[MusicLyrics] NetEase: matched song (id: " + songId + ", name: " + bestSong.name + ", artist: " + artistName + ")");
                root._fetchNeteaseLyrics(songId, expectedTitle, expectedArtist);
            } catch (e) {
                root._setNeteaseNotFound(status.error);
                console.warn("[MusicLyrics] NetEase: failed to parse search response — " + e);
            }
        }, function (errMsg) {
            root._setNeteaseNotFound(status.error);
            console.warn("[MusicLyrics] NetEase: search request failed — " + errMsg);
        }, _neteaseHeaders());
    }

    function _fetchNeteaseLyrics(songId, expectedTitle, expectedArtist) {
        var url = "https://music.163.com/api/song/lyric?id=" + songId + "&lv=-1&kv=-1&tv=-1";
        console.log("[MusicLyrics] NetEase: lyrics URL = " + url);

        root._cancelActiveFetch = _xhrGet(url, 15000, function (responseText, httpStatus) {
            if (expectedTitle !== root._lastFetchedTrack || expectedArtist !== root._lastFetchedArtist)
                return;

            try {
                var result = JSON.parse(responseText);
                if (result.code !== 200) {
                    root._setNeteaseNotFound(status.notFound);
                    console.info("[MusicLyrics] ✗ NetEase: lyrics API error (code: " + result.code + ")");
                    return;
                }

                var lrcText = result.lrc && result.lrc.lyric ? result.lrc.lyric.trim() : "";
                if (!lrcText) {
                    root._setNeteaseNotFound(status.notFound);
                    console.info("[MusicLyrics] ✗ NetEase: no lyrics for song id " + songId);
                    return;
                }

                var lines = root.parseLrc(lrcText);
                if (lines.length === 0) {
                    root._setNeteaseNotFound(status.skippedPlain);
                    console.info("[MusicLyrics] ✗ NetEase: only plain lyrics for song id " + songId + " (skipping, synced only)");
                    return;
                }

                root.lyricsLines = lines;
                root.neteaseStatus = status.found;
                root.lyricStatus = lyricState.synced;
                root.lyricSource = lyricSrc.netease;
                console.info("[MusicLyrics] ✓ NetEase: synced lyrics found (" + lines.length + " lines) for \"" + expectedTitle + "\"");
                root._cancelActiveFetch = null;
                if (root.cachingEnabled)
                    root.writeToCache(expectedTitle, expectedArtist, lines, lyricSrc.netease);
            } catch (e) {
                root._setNeteaseNotFound(status.error);
                console.warn("[MusicLyrics] NetEase: failed to parse lyrics response — " + e);
            }
        }, function (errMsg) {
            root._setNeteaseNotFound(status.error);
            console.warn("[MusicLyrics] NetEase: lyrics request failed — " + errMsg);
        }, _neteaseHeaders());
    }

    // -------------------------------------------------------------------------
    // LRC parser
    // -------------------------------------------------------------------------

    function parseLrc(lrcText) {
        var timeRegex = /\[(\d{2}):(\d{2})\.(\d{2,3})\]/;
        var result = lrcText.split("\n").reduce(function (acc, rawLine) {
            var line = rawLine.trim();
            if (!line)
                return acc;
            var match = timeRegex.exec(line);
            if (!match)
                return acc;
            var millis = parseInt(match[3]);
            if (match[3].length === 2)
                millis *= 10;
            acc.push({
                time: parseInt(match[1]) * 60 + parseInt(match[2]) + millis / 1000,
                text: line.replace(/\[\d{2}:\d{2}\.\d{2,3}\]/g, "").trim()
            });
            return acc;
        }, []);
        result.sort(function (a, b) {
            return a.time - b.time;
        });
        return result;
    }

    // -------------------------------------------------------------------------
    // Position tracking for synced lyrics
    // -------------------------------------------------------------------------

    Timer {
        id: positionTimer
        interval: 200
        running: activePlayer && lyricsLines.length > 0
        repeat: true
        onTriggered: {
            var pos = activePlayer.position || 0;
            var newIndex = -1;
            for (var i = lyricsLines.length - 1; i >= 0; i--) {
                if (pos >= lyricsLines[i].time) {
                    newIndex = i;
                    break;
                }
            }
            if (newIndex !== currentLineIndex)
                currentLineIndex = newIndex;
        }
    }

    // -------------------------------------------------------------------------
    // Status chip helpers
    // -------------------------------------------------------------------------

    readonly property var _chipMeta: ({
            [status.searching]: {
                color: Theme.secondary,
                icon: "hourglass_top",
                label: "Searching…"
            },
            [status.found]: {
                color: Theme.primary,
                icon: "check_circle",
                label: "Found — Synced lyrics"
            },
            [status.notFound]: {
                color: Theme.warning,
                icon: "cancel",
                label: "Not found"
            },
            [status.error]: {
                color: Theme.error,
                icon: "error",
                label: "Error"
            },
            [status.skippedFound]: {
                color: Theme.warning,
                icon: "block",
                label: "Skipped — Already found"
            },
            [status.skippedPlain]: {
                color: Theme.warning,
                icon: "block",
                label: "Skipped — Plain lyrics only"
            },
            [status.cacheHit]: {
                color: Theme.primary,
                icon: "check_circle",
                label: "Hit — Lyrics loaded from cache"
            },
            [status.cacheMiss]: {
                color: Theme.warning,
                icon: "cancel",
                label: "Miss — Not in cache"
            },
            [status.cacheDisabled]: {
                color: Theme.surfaceVariantText,
                icon: "do_not_disturb_on",
                label: "Disabled"
            }
        })

    function _chip(val) {
        return _chipMeta[val] ?? {
            color: Theme.surfaceContainerHighest,
            icon: "radio_button_unchecked",
            label: "Idle"
        };
    }

    function chipColor(val) {
        return _chip(val).color;
    }
    function chipIcon(val) {
        return _chip(val).icon;
    }
    function chipLabel(val) {
        return _chip(val).label;
    }

    // -------------------------------------------------------------------------
    // Bar Pills: show current lyric line
    // -------------------------------------------------------------------------

    horizontalBarPill: root._isMusicPlayer ? hPillComponent : null

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
                        name: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "lyrics" : "pause"
                        size: Theme.fontSizeSmall
                        color: Theme.background
                    }

                    StyledText {
                        text: root.lyricSource === lyricSrc.mpris ? "MPRIS" : root.lyricSource === lyricSrc.lrclib ? "lrclib" : root.lyricSource === lyricSrc.netease ? "NetEase" : ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.background
                        anchors.verticalCenter: parent.verticalCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        visible: root.lyricsLines.length > 0
                    }
                }
            }

            StyledText {
                text: root.currentLyricText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                maximumLineCount: 1
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 300)
            }
        }
    }

    verticalBarPill: root._isMusicPlayer ? vPillComponent : null

    Component {
        id: vPillComponent
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "lyrics"
                size: Theme.iconSize
                color: root.lyricsLines.length > 0 ? Theme.primary : Theme.surfaceVariantText
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
    // Popout: Now Playing + Lyrics Sources
    // -------------------------------------------------------------------------

    function _formatDuration(seconds) {
        if (seconds <= 0) return "—";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + ("0" + s).slice(-2);
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Music Lyrics"

            Item {
                width: parent.width
                implicitHeight: popoutLayout.implicitHeight

                Column {
                    id: popoutLayout
                    width: parent.width
                    spacing: Theme.spacingM

                    // ── Now Playing Card ──
                    Rectangle {
                        width: parent.width
                        height: nowPlayingContent.implicitHeight + Theme.spacingM * 2
                        radius: Theme.cornerRadius
                        color: root.activePlayer
                              ? Theme.withAlpha(Theme.primary, 0.08)
                              : Theme.withAlpha(Theme.surfaceContainerHighest, 0.5)

                        Row {
                            id: nowPlayingContent
                            anchors {
                                left: parent.left; right: parent.right
                                top: parent.top
                                margins: Theme.spacingM
                            }
                            spacing: Theme.spacingM

                            // Track info column (takes remaining space)
                            Column {
                                width: _coverArt.visible
                                       ? parent.width - _coverArt.width - parent.spacing
                                       : parent.width
                                spacing: Theme.spacingS

                                // Header row: icon + "Now Playing"
                                Row {
                                    spacing: Theme.spacingS
                                    width: parent.width

                                    DankIcon {
                                        name: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                                              ? "play_circle" : "pause_circle"
                                        size: 20
                                        color: root.activePlayer ? Theme.primary : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: root.activePlayer ? "Now Playing - " + (root.activePlayer.identity || "Unknown Player") : "No Active Player"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.DemiBold
                                        color: root.activePlayer ? Theme.primary : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Song title
                                StyledText {
                                    width: parent.width
                                    text: root.currentTitle || "—"
                                    font.pixelSize: Theme.fontSizeLarge + 2
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    wrapMode: Text.WordWrap
                                    visible: root.activePlayer
                                }

                                // Artist & Album
                                Column {
                                    width: parent.width
                                    spacing: 2
                                    visible: root.activePlayer

                                    Row {
                                        spacing: Theme.spacingXS
                                        DankIcon {
                                            name: "person"
                                            size: 14
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        StyledText {
                                            text: root.currentArtist || "Unknown Artist"
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Row {
                                        spacing: Theme.spacingXS
                                        visible: root.currentAlbum !== ""
                                        DankIcon {
                                            name: "album"
                                            size: 14
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        StyledText {
                                            text: root.currentAlbum
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Progress bar with timestamps
                                Column {
                                    width: parent.width
                                    spacing: 4
                                    visible: root.activePlayer && root.currentDuration > 0

                                    DankSeekbar {
                                        id: progressSeekbar
                                        width: parent.width
                                        height: 20
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        activePlayer: root.activePlayer
                                    }

                                    // Poll MPRIS position to keep seekbar and time text updated
                                    Timer {
                                        interval: 50
                                        running: root.activePlayer !== null
                                        repeat: true
                                        onTriggered: {
                                            if (progressSeekbar && root.activePlayer) {
                                                try {
                                                    var pos = root.activePlayer.position || 0;
                                                    var len = Math.max(1, root.activePlayer.length || 1);
                                                    progressSeekbar.value = Math.min(1, pos / len);
                                                } catch (e) {}
                                            }
                                            root._forceUpdate = !root._forceUpdate;
                                        }
                                    }

                                    Row {
                                        width: parent.width

                                        StyledText {
                                            id: _currentTime
                                            text: {
                                                void root._forceUpdate; // depend on polling toggle
                                                if (!activePlayer)
                                                    return "0:00";
                                                const rawPos = Math.max(0, activePlayer.position || 0);
                                                const pos = activePlayer.length ? rawPos % Math.max(1, activePlayer.length) : rawPos;
                                                const minutes = Math.floor(pos / 60);
                                                const seconds = Math.floor(pos % 60);
                                                const timeStr = minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
                                                return timeStr;
                                            }
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            color: Theme.surfaceVariantText
                                        }

                                        Item { width: parent.width - _currentTime.implicitWidth - _endTime.implicitWidth; height: 1 }

                                        StyledText {
                                            id: _endTime
                                            text: {
                                                if (!activePlayer || !activePlayer.length)
                                                    return "0:00";
                                                const dur = Math.max(0, activePlayer.length || 0);
                                                const minutes = Math.floor(dur / 60);
                                                const seconds = Math.floor(dur % 60);
                                                return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
                                            }
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            color: Theme.surfaceVariantText
                                        }
                                    }
                                }
                            }

                            // Album cover art
                            DankAlbumArt {
                                id: _coverArt
                                width: 80
                                height: 80
                                visible: root.activePlayer && (root.activePlayer.trackArtUrl ?? "") !== ""
                                anchors.verticalCenter: parent.verticalCenter
                                activePlayer: root.activePlayer
                                showAnimation: true
                            }
                        }
                    }

                    // ── Section label ──
                    StyledText {
                        text: "Lyrics Sources"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.surfaceVariantText
                        leftPadding: Theme.spacingXS
                    }

                    // ── Source Cards ──
                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        SourceCard {
                            width: parent.width
                            icon: "music_note"
                            label: "MPRIS"
                            sourceStatus: root.mprisStatus
                        }

                        SourceCard {
                            width: parent.width
                            icon: "cached"
                            label: "Cache"
                            sourceStatus: root.cacheStatus
                        }

                        SourceCard {
                            width: parent.width
                            icon: "library_music"
                            label: "lrclib"
                            sourceStatus: root.lrclibStatus
                        }

                        SourceCard {
                            width: parent.width
                            icon: "cloud"
                            label: "NetEase"
                            sourceStatus: root.neteaseStatus
                        }
                    }
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

        height: 44
        radius: Theme.cornerRadius
        color: sourceStatus === 0
               ? Theme.withAlpha(Theme.surfaceContainerHighest, 0.3)
               : Theme.withAlpha(root.chipColor(sourceStatus), 0.06)
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
                       : Theme.withAlpha(root.chipColor(sourceCard.sourceStatus), 0.15)
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: sourceCard.icon
                    size: 14
                    color: sourceCard.sourceStatus === 0
                           ? Theme.surfaceVariantText
                           : root.chipColor(sourceCard.sourceStatus)
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
                    color: Theme.withAlpha(root.chipColor(sourceCard.sourceStatus), 0.15)

                    Row {
                        id: statusChipContent
                        anchors.centerIn: parent
                        spacing: 4

                        DankIcon {
                            name: root.chipIcon(sourceCard.sourceStatus)
                            size: 12
                            color: root.chipColor(sourceCard.sourceStatus)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.chipLabel(sourceCard.sourceStatus)
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: root.chipColor(sourceCard.sourceStatus)
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

    popoutWidth: 380
    popoutHeight: 520

    Component.onCompleted: {
        console.info("[MusicLyrics] Plugin loaded");
    }
}
