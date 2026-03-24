# Get Tracks from a Spotify Playlist

Retrieves all tracks from a Spotify playlist by URL or ID.

## Usage

``` r
get_playlist_tracks(playlist_url, token = NULL)
```

## Arguments

- playlist_url:

  Spotify playlist URL or ID

- token:

  Spotify token (uses saved token if NULL)

## Value

Data frame with track information

## Examples

``` r
if (FALSE) { # \dontrun{
# Using playlist URL
playlist <- get_playlist_tracks(
  "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
)

# Using just the playlist ID
playlist <- get_playlist_tracks("37i9dQZF1DXcBWIGoYBM5M")

# View tracks
print(playlist[, c("track_name", "artist_name")])
} # }
```
