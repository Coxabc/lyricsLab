# Get Recently Played Tracks

Retrieves your 50 most recently played tracks from Spotify. This is the
maximum the Spotify API allows in a single request.

## Usage

``` r
get_recently_played(token = NULL)
```

## Arguments

- token:

  Spotify token (uses saved token if NULL)

## Value

Data frame with track information and play times containing:

- played_at - POSIXct timestamp of when the track was played

- track_name - Track title

- track_id - Spotify track ID

- artist_name - Artist name(s)

- artist_id - Primary artist ID

- album_name - Album title

- album_id - Spotify album ID

- duration_ms - Track duration in milliseconds

- popularity - Spotify popularity score (0-100)

## Examples

``` r
if (FALSE) { # \dontrun{
history <- get_recently_played()

# Most played artists
sort(table(history$artist_name), decreasing = TRUE)
} # }
```
