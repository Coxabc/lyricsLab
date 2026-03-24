# Get Top Tracks

Retrieves your top tracks from Spotify.

## Usage

``` r
get_top_tracks(time_range = "medium_term", limit = 20, token = NULL)
```

## Arguments

- time_range:

  Time range: "short_term" (4 weeks), "medium_term" (6 months), or
  "long_term" (all time). Default "medium_term"

- limit:

  Number of tracks to retrieve (max 50). Default 20

- token:

  Spotify token (uses saved token if NULL)

## Value

Data frame with track information

## Examples

``` r
if (FALSE) { # \dontrun{
# Top tracks all time
top_tracks <- get_top_tracks(time_range = "long_term", limit = 50)
print(top_tracks[, c("rank", "track_name", "artist_name")])
} # }
```
