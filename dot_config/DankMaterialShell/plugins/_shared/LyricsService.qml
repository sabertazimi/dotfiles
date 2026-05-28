import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    // -------------------------------------------------------------------------
    // Configuration
    // -------------------------------------------------------------------------

    property bool cachingEnabled: true

    // -------------------------------------------------------------------------
    // Enum values
    // -------------------------------------------------------------------------

    // Chip-visible statuses
    readonly property int statusNone: 0
    readonly property int statusSearching: 1
    readonly property int statusFound: 2
    readonly property int statusNotFound: 3
    readonly property int statusError: 4
    readonly property int statusSkippedFound: 5
    readonly property int statusSkippedPlain: 6
    readonly property int statusCacheHit: 11
    readonly property int statusCacheMiss: 12
    readonly property int statusCacheDisabled: 13

    // Lyrics-fetch lifecycle
    readonly property int stateIdle: 0
    readonly property int stateLoading: 1
    readonly property int stateSynced: 2
    readonly property int stateNotFound: 3

    // Lyrics sources
    readonly property int srcNone: 0
    readonly property int srcMpris: 1
    readonly property int srcCache: 2
    readonly property int srcLrclib: 3
    readonly property int srcNetease: 4

    // -------------------------------------------------------------------------
    // Track info
    // -------------------------------------------------------------------------

    readonly property MprisPlayer activePlayer: MprisController.activePlayer

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

    readonly property bool isMusicPlayer: {
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

    onIsMusicPlayerChanged: {
        if (isMusicPlayer && currentTitle)
            fetchDebounceTimer.restart();
    }

    // -------------------------------------------------------------------------
    // Lyrics state
    // -------------------------------------------------------------------------

    property var lyricsLines: []
    property int currentLineIndex: -1
    property bool lyricsLoading: lyricStatus === stateLoading
    property string _lastFetchedTrack: ""
    property string _lastFetchedArtist: ""
    property var _cancelActiveFetch: null

    // Chip status properties
    property int mprisStatus: statusNone
    property int cacheStatus: statusNone
    property int lrclibStatus: statusNone
    property int neteaseStatus: statusNone

    // Fetch state and source
    property int lyricStatus: stateIdle
    property int lyricSource: srcNone

    // Current lyric line for display
    property string currentLyricText: {
        if (lyricsLoading)
            return "Searching lyrics…";
        if (lyricsLines.length > 0 && currentLineIndex >= 0)
            return lyricsLines[currentLineIndex].text || "♪ ♪ ♪";
        if (currentTitle)
            return currentTitle;
        return "No lyrics";
    }

    // Next lyric line for preview
    readonly property string nextLyricText: {
        if (lyricsLines.length > 0 && currentLineIndex >= 0 && currentLineIndex + 1 < lyricsLines.length)
            return lyricsLines[currentLineIndex + 1].text || "";
        return "";
    }

    // -------------------------------------------------------------------------
    // Debounce timer
    // -------------------------------------------------------------------------

    Timer {
        id: fetchDebounceTimer
        interval: 300
        onTriggered: root.fetchLyricsIfNeeded()
    }
    onCurrentTitleChanged: fetchDebounceTimer.restart()
    onCurrentArtistChanged: fetchDebounceTimer.restart()

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _resetLyricsState() {
        lyricsLines = [];
        currentLineIndex = -1;
        mprisStatus = statusNone;
        cacheStatus = statusNone;
        lrclibStatus = statusNone;
        neteaseStatus = statusNone;
        lyricStatus = stateLoading;
        lyricSource = srcNone;
    }

    // lrclib fail → NetEase
    function _setLrclibNotFound(lrclibStatusVal) {
        lrclibStatus = lrclibStatusVal;
        _fetchFromNetease(_lastFetchedTrack, _lastFetchedArtist);
    }

    // NetEase fail → final
    function _setNeteaseNotFound(neteaseStatusVal) {
        neteaseStatus = neteaseStatusVal;
        lyricStatus = stateNotFound;
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
                console.info("[LyricsService] Cache: written for \"" + cTitle + "\" by " + cArtist + " (" + path + ")");
                destroy();
            }
            onSaveFailed: {
                console.warn("[LyricsService] Cache: failed to write for \"" + cTitle + "\"");
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
        if (!isMusicPlayer)
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
        console.info("[LyricsService] ▶ Track changed: \"" + currentTitle + "\" by " + currentArtist + (currentAlbum ? " [" + currentAlbum + "]" : "") + " (" + durationStr + ")");

        var capturedTitle = currentTitle;
        var capturedArtist = currentArtist;

        // 1. Try MPRIS metadata first
        var mprisLyricsText = "";
        if (activePlayer && activePlayer.metadata) {
            mprisLyricsText = activePlayer.metadata["xesam:asText"] || "";
        }
        if (mprisLyricsText.length > 0) {
            var mprisLines = parseLrc(mprisLyricsText);
            if (mprisLines.length > 0) {
                var instrumental = mprisLines.some(function (l) { return (l.text || "").indexOf("纯音乐，请欣赏") !== -1; });
                if (mprisLines.length >= 5 || currentDuration <= 30 || instrumental) {
                    lyricsLines = mprisLines;
                    mprisStatus = statusFound;
                    lyricStatus = stateSynced;
                    lyricSource = srcMpris;
                    cacheStatus = statusSkippedFound;
                    lrclibStatus = statusSkippedFound;
                    neteaseStatus = statusSkippedFound;
                    console.info("[LyricsService] ✓ MPRIS: synced lyrics found (" + mprisLines.length + " lines) for \"" + currentTitle + "\"");
                    return;
                }
                mprisStatus = statusNotFound;
                console.info("[LyricsService] ✗ MPRIS: only " + mprisLines.length + " synced lines for " + Math.round(currentDuration) + "s track, falling through");
            } else {
                mprisStatus = statusSkippedPlain;
                console.info("[LyricsService] ✗ MPRIS: only plain lyrics found (skipping, synced only)");
            }
        } else {
            mprisStatus = statusNotFound;
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
                    root.lyricStatus = stateSynced;
                    root.lyricSource = cached.source > 0 ? cached.source : srcCache;
                    root.cacheStatus = statusCacheHit;
                    root.lrclibStatus = statusSkippedFound;
                    root.neteaseStatus = statusSkippedFound;
                    console.info("[LyricsService] ✓ Cache: lyrics loaded for \"" + capturedTitle + "\" (" + cached.lines.length + " lines)");
                    return;
                }
                root.cacheStatus = statusCacheMiss;
                _startFetch();
            });
        } else {
            cacheStatus = statusCacheDisabled;
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
                console.warn("[LyricsService] _xhrGet: " + errMsg + " — retrying (attempt " + (attempt + 1) + ", " + retriesLeft + " left): " + url);
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
            console.info("[LyricsService] ⊘ XHR cancelled: " + url);
        };
    }

    // -------------------------------------------------------------------------
    // lrclib.net fetch
    // -------------------------------------------------------------------------

    function _fetchFromLrclib(expectedTitle, expectedArtist) {
        if (lyricStatus === stateSynced) {
            lrclibStatus = statusSkippedFound;
            console.info("[LyricsService] lrclib: skipped (synced lyrics already found)");
            return;
        }

        lrclibStatus = statusSearching;
        console.info("[LyricsService] lrclib: searching for \"" + expectedTitle + "\" by " + expectedArtist);

        var url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(expectedArtist) + "&track_name=" + encodeURIComponent(expectedTitle);
        if (currentAlbum)
            url += "&album_name=" + encodeURIComponent(currentAlbum);
        if (currentDuration > 0)
            url += "&duration=" + Math.round(currentDuration);

        root._cancelActiveFetch = _xhrGet(url, 20000, function (responseText, httpStatus) {
            var rawData = (responseText || "").trim();
            console.log("[LyricsService] lrclib: response length = " + rawData.length);
            if (rawData.length === 0) {
                root._setLrclibNotFound(statusError);
                console.warn("[LyricsService] lrclib: empty response (HTTP " + httpStatus + ")");
                return;
            }
            try {
                var result = JSON.parse(rawData);
                if (result.statusCode === 404 || result.error) {
                    root._setLrclibNotFound(statusNotFound);
                    console.info("[LyricsService] ✗ lrclib: no lyrics found for \"" + expectedTitle + "\"");
                } else if (result.syncedLyrics) {
                    root.lyricsLines = root.parseLrc(result.syncedLyrics);
                    root.lrclibStatus = statusFound;
                    root.neteaseStatus = statusSkippedFound;
                    root.lyricStatus = stateSynced;
                    root.lyricSource = srcLrclib;
                    console.info("[LyricsService] ✓ lrclib: synced lyrics found (" + root.lyricsLines.length + " lines) for \"" + expectedTitle + "\"");
                    root._cancelActiveFetch = null;
                    if (root.cachingEnabled)
                        root.writeToCache(expectedTitle, expectedArtist, root.lyricsLines, root.srcLrclib);
                } else if (result.plainLyrics) {
                    root._setLrclibNotFound(statusSkippedPlain);
                    console.info("[LyricsService] ✗ lrclib: only plain lyrics found for \"" + expectedTitle + "\" (skipping, synced only)");
                } else {
                    root._setLrclibNotFound(statusNotFound);
                    console.info("[LyricsService] ✗ lrclib: response contained no lyrics for \"" + expectedTitle + "\"");
                }
            } catch (e) {
                root._setLrclibNotFound(statusError);
                console.warn("[LyricsService] lrclib: failed to parse response — " + e);
                console.warn("[LyricsService] lrclib: raw data: " + rawData.substring(0, 200));
            }
        }, function (errMsg) {
            root._setLrclibNotFound(statusError);
            console.warn("[LyricsService] lrclib: request failed — " + errMsg);
        });
    }

    // -------------------------------------------------------------------------
    // NetEase Cloud Music fetch
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
        if (lyricStatus === stateSynced) {
            neteaseStatus = statusSkippedFound;
            console.info("[LyricsService] NetEase: skipped (synced lyrics already found)");
            return;
        }

        neteaseStatus = statusSearching;
        console.info("[LyricsService] NetEase: searching for \"" + expectedTitle + "\" by " + expectedArtist);

        var keyword = expectedTitle + " " + expectedArtist;
        var searchUrl = "https://music.163.com/api/search/get?s=" + encodeURIComponent(keyword)
            + "&type=1&offset=0&total=true&limit=20";

        root._cancelActiveFetch = _xhrGet(searchUrl, 15000, function (responseText, httpStatus) {
            if (expectedTitle !== root._lastFetchedTrack || expectedArtist !== root._lastFetchedArtist)
                return;

            try {
                var result = JSON.parse(responseText);
                if (result.code !== 200 || !result.result || !result.result.songs || result.result.songs.length === 0) {
                    root._setNeteaseNotFound(statusNotFound);
                    console.info("[LyricsService] ✗ NetEase: no search results for \"" + expectedTitle + "\"");
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
                console.info("[LyricsService] NetEase: matched song (id: " + songId + ", name: " + bestSong.name + ", artist: " + artistName + ")");
                root._fetchNeteaseLyrics(songId, expectedTitle, expectedArtist);
            } catch (e) {
                root._setNeteaseNotFound(statusError);
                console.warn("[LyricsService] NetEase: failed to parse search response — " + e);
            }
        }, function (errMsg) {
            root._setNeteaseNotFound(statusError);
            console.warn("[LyricsService] NetEase: search request failed — " + errMsg);
        }, _neteaseHeaders());
    }

    function _fetchNeteaseLyrics(songId, expectedTitle, expectedArtist) {
        var url = "https://music.163.com/api/song/lyric?id=" + songId + "&lv=-1&kv=-1&tv=-1";
        console.log("[LyricsService] NetEase: lyrics URL = " + url);

        root._cancelActiveFetch = _xhrGet(url, 15000, function (responseText, httpStatus) {
            if (expectedTitle !== root._lastFetchedTrack || expectedArtist !== root._lastFetchedArtist)
                return;

            try {
                var result = JSON.parse(responseText);
                if (result.code !== 200) {
                    root._setNeteaseNotFound(statusNotFound);
                    console.info("[LyricsService] ✗ NetEase: lyrics API error (code: " + result.code + ")");
                    return;
                }

                var lrcText = result.lrc && result.lrc.lyric ? result.lrc.lyric.trim() : "";
                if (!lrcText) {
                    root._setNeteaseNotFound(statusNotFound);
                    console.info("[LyricsService] ✗ NetEase: no lyrics for song id " + songId);
                    return;
                }

                var lines = root.parseLrc(lrcText);
                if (lines.length === 0) {
                    root._setNeteaseNotFound(statusSkippedPlain);
                    console.info("[LyricsService] ✗ NetEase: only plain lyrics for song id " + songId + " (skipping, synced only)");
                    return;
                }

                root.lyricsLines = lines;
                root.neteaseStatus = statusFound;
                root.lyricStatus = stateSynced;
                root.lyricSource = srcNetease;
                console.info("[LyricsService] ✓ NetEase: synced lyrics found (" + lines.length + " lines) for \"" + expectedTitle + "\"");
                root._cancelActiveFetch = null;
                if (root.cachingEnabled)
                    root.writeToCache(expectedTitle, expectedArtist, lines, root.srcNetease);
            } catch (e) {
                root._setNeteaseNotFound(statusError);
                console.warn("[LyricsService] NetEase: failed to parse lyrics response — " + e);
            }
        }, function (errMsg) {
            root._setNeteaseNotFound(statusError);
            console.warn("[LyricsService] NetEase: lyrics request failed — " + errMsg);
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
            [statusSearching]: {
                color: Theme.secondary,
                icon: "hourglass_top",
                label: "Searching…"
            },
            [statusFound]: {
                color: Theme.primary,
                icon: "check_circle",
                label: "Found — Synced lyrics"
            },
            [statusNotFound]: {
                color: Theme.warning,
                icon: "cancel",
                label: "Not found"
            },
            [statusError]: {
                color: Theme.error,
                icon: "error",
                label: "Error"
            },
            [statusSkippedFound]: {
                color: Theme.surfaceVariantText,
                icon: "block",
                label: "Skipped — Already found"
            },
            [statusSkippedPlain]: {
                color: Theme.surfaceVariantText,
                icon: "block",
                label: "Skipped — Plain lyrics only"
            },
            [statusCacheHit]: {
                color: Theme.primary,
                icon: "check_circle",
                label: "Hit — Loaded from cache"
            },
            [statusCacheMiss]: {
                color: Theme.warning,
                icon: "cancel",
                label: "Miss — Not in cache"
            },
            [statusCacheDisabled]: {
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

    function sourceName(srcVal) {
        switch (srcVal) {
        case srcMpris: return "MPRIS";
        case srcCache: return "Cache";
        case srcLrclib: return "lrclib";
        case srcNetease: return "NetEase";
        default: return "";
        }
    }

    Component.onCompleted: {
        console.info("[LyricsService] Initialized");
    }
}
