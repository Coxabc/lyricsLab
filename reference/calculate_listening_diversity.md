# Calculate Listening Diversity

Measures how diverse your listening habits are using Shannon entropy.
Prints a clean summary to the console and returns results invisibly.

## Usage

``` r
calculate_listening_diversity(history_df)
```

## Arguments

- history_df:

  Data frame from
  [`get_recently_played()`](https://coxabc.github.io/lyricsLab/reference/get_recently_played.md)

## Value

Invisibly returns a list containing:

- unique_artists - Number of unique artists

- unique_tracks - Number of unique tracks

- total_plays - Total number of plays

- top_artist - Most played artist

- top_artist_percentage - Percentage of plays by top artist

- diversity_score - Score from 0-100 (higher = more diverse)

- interpretation - Text description of diversity

## Examples

``` r
if (FALSE) { # \dontrun{
history <- get_recently_played(n_total = 500)
calculate_listening_diversity(history)

playlist <- get_playlist_tracks("https://open.spotify.com/playlist/123abc")
calculate_listening_diversity(playlist)
} # }
```
