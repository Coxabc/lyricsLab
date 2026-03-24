# Analyze Playlist Lyrics

Gets lyrics and analyzes all songs in a Spotify playlist.

## Usage

``` r
analyze_playlist(playlist_url, max_songs = 50, delay = 2, token = NULL)
```

## Arguments

- playlist_url:

  Spotify playlist URL or ID

- max_songs:

  Maximum number of songs to analyze (default 50)

- delay:

  Delay between API calls in seconds (default 2)

- token:

  Spotify token (uses saved token if NULL)

## Value

List with playlist tracks and lyrics analysis

## Examples

``` r
if (FALSE) { # \dontrun{
analysis <- analyze_playlist(
  "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M",
  max_songs = 20
)
print(analysis)
plot_sentiment(analysis)
} # }
```
