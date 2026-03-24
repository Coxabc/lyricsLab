# Spotify Integration: Playlists and Listening History

This vignette covers the Spotify side of lyricsLab: authenticating,
pulling your listening data, analyzing entire playlists, and visualizing
listening patterns.

## Authentication

You need a Spotify app before you start. Go to
<https://developer.spotify.com/dashboard>, create an app, and set the
redirect URI to exactly `http://127.0.0.1:1410/`.

Store your credentials in your environment — the easiest way is to add
them to `~/.Renviron` so they load automatically every session:

    SPOTIFY_CLIENT_ID=your_client_id
    SPOTIFY_CLIENT_SECRET=your_client_secret
    GENIUS_API_TOKEN=your_genius_token

Then authenticate:

``` r
library(lyricsLab)
spotify_auth()
```

This opens a browser window. Log in, authorize the app, and you’ll be
redirected back automatically. The token is saved to your global
environment for the session. It expires after about an hour — just run
[`spotify_auth()`](https://coxabc.github.io/lyricsLab/reference/spotify_auth.md)
again if you hit auth errors.

The scopes requested are: recently played, top tracks, saved library,
and private playlists.

## Your listening history

[`get_recently_played()`](https://coxabc.github.io/lyricsLab/reference/get_recently_played.md)
returns your 50 most recent plays (the maximum Spotify allows per
request):

``` r
history <- get_recently_played()
#>
#> === Recently Played ===
#>   Tracks retrieved:  50
#>   From:              2024-01-10 08:14
#>   To:                2024-01-12 23:47
#>   Time span:         63.5 hours
```

The returned data frame has these columns: `played_at`, `track_name`,
`track_id`, `artist_name`, `artist_id`, `album_name`, `album_id`,
`duration_ms`, `popularity`.

Quick summaries directly from the data frame:

``` r
# Most played artists
sort(table(history$artist_name), decreasing = TRUE)

# Most played tracks
sort(table(history$track_name), decreasing = TRUE)

# Average popularity of what you've been listening to
mean(history$popularity, na.rm = TRUE)
```

### Listening patterns

[`plot_listening_patterns()`](https://coxabc.github.io/lyricsLab/reference/plot_listening_patterns.md)
takes the history data frame and a `type` argument:

``` r
# By hour of day
plot_listening_patterns(history, type = "hourly")

# By date (trend over time)
plot_listening_patterns(history, type = "daily")

# By day of week
plot_listening_patterns(history, type = "weekly")
```

### Listening diversity

[`calculate_listening_diversity()`](https://coxabc.github.io/lyricsLab/reference/calculate_listening_diversity.md)
measures how spread out your listening is across artists using Shannon
entropy, producing a 0–100 diversity score:

``` r
calculate_listening_diversity(history)
#>
#> === Listening Diversity ===
#>   Unique artists:    23
#>   Unique tracks:     47
#>   Total plays:       50
#>   Top artist:        Taylor Swift (18.0% of plays)
#>   Diversity score:   71.4 / 100
#>   Interpretation:    Moderately diverse - good mix of variety and favorites
```

A score above 80 means you explore broadly; below 40 means you mostly
stick to a handful of artists.

## Your top tracks

[`get_top_tracks()`](https://coxabc.github.io/lyricsLab/reference/get_top_tracks.md)
pulls your Spotify top tracks. The `time_range` argument controls the
window:

``` r
# Last 4 weeks
recent_tops <- get_top_tracks(time_range = "short_term",  limit = 20)

# Last 6 months (default)
medium_tops <- get_top_tracks(time_range = "medium_term", limit = 20)

# All time
all_time    <- get_top_tracks(time_range = "long_term",   limit = 50)

# View ranked list
all_time[, c("rank", "track_name", "artist_name", "popularity")]
```

## Playlist tracks

[`get_playlist_tracks()`](https://coxabc.github.io/lyricsLab/reference/get_playlist_tracks.md)
accepts a full Spotify URL or just the playlist ID:

``` r
playlist <- get_playlist_tracks(
  "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
)

# Or just the ID
playlist <- get_playlist_tracks("37i9dQZF1DXcBWIGoYBM5M")
```

This works for playlists of any size. The returned data frame includes
`track_name`, `artist_name`, `album_name`, `popularity`, `duration_ms`,
`added_at`, and `added_by`.

``` r
# Most popular tracks in the playlist
playlist[order(-playlist$popularity), c("track_name", "artist_name", "popularity")]

# Artists with the most tracks
sort(table(playlist$artist_name), decreasing = TRUE)
```

## Playlist lyrics analysis

[`analyze_playlist()`](https://coxabc.github.io/lyricsLab/reference/analyze_playlist.md)
combines playlist fetching with Genius lyrics retrieval and full
analysis for every song. It calls
[`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md),
[`sentiment_score()`](https://coxabc.github.io/lyricsLab/reference/sentiment_score.md),
[`complexity_score()`](https://coxabc.github.io/lyricsLab/reference/complexity_score.md),
and
[`theme_detection()`](https://coxabc.github.io/lyricsLab/reference/theme_detection.md)
for each track, with rate limiting between requests to avoid hitting API
limits.

``` r
analysis <- analyze_playlist(
  "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M",
  max_songs = 20,   # limit for speed, default 50
  delay     = 2     # seconds between requests
)
```

Progress is printed as each song is processed:

    Analyzing lyrics for 20 songs...

    [1/20] Anti-Hero by Taylor Swift
      + Sentiment: -0.21 | Complexity: 28.4/100 | Theme: Self-Reflection
    [2/20] Flowers by Miley Cyrus
      + Sentiment: 0.84 | Complexity: 31.2/100 | Theme: Empowerment
    ...

    === PLAYLIST ANALYSIS COMPLETE ===
    Playlist: Today's Top Hits
    Analyzed: 17/20 tracks
    Avg sentiment: 0.12
    Avg complexity: 29.8/100
    Most common theme: Love/Romance

Songs that can’t be found on Genius (instrumentals, very new releases,
non-English tracks) are skipped and listed at the end.

### Playlist plots

Each plot function takes the analysis result directly:

``` r
# Distribution of sentiment scores across the playlist
plot_sentiment(analysis)

# Distribution of complexity scores
plot_complexity(analysis)

# Which themes appear most across the playlist
plot_themes(analysis)

# Is there a relationship between complexity and sentiment?
plot_scatter(analysis)

# The 10 most lyrically complex songs
plot_top_complex(analysis)
```
