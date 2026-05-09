# Music Lyrics

A DankMaterialShell widget plugin that displays synced music lyrics.

Forked from [@Gasiyu](https://github.com/Gasiyu/dms-plugin-musiclyrics)
to add NetEase Cloud Music (网易云音乐) as an additional lyrics source,
improving coverage for non-English (especially CJK) songs.

## Lyrics Sources

The plugin searches for synced lyrics in the following order:

1. `MPRIS`: player metadata via `xesam:asText` (instant, no network)
2. Cache: local file cache (`~/.cache/music-lyrics/`)
3. `lrclib`: [lrclib.net](https://lrclib.net) open lyrics database
4. `NetEase`: [NetEase Cloud Music](https://music.163.com) (网易云音乐)
