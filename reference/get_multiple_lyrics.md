# Get Multiple Lyrics

Batch retrieve lyrics for multiple songs.

## Usage

``` r
get_multiple_lyrics(artist, songs, delay = 2, access_token = NULL)
```

## Arguments

- artist:

  Character string or vector of artist names

- songs:

  Character vector of song titles

- delay:

  Numeric; seconds to wait between requests. Default 2

- access_token:

  Genius API token (optional)

## Value

A list of lyrics_lab objects

## Examples

``` r
if (FALSE) { # \dontrun{
songs <- c("Anti-Hero", "Karma", "Lavender Haze")
lyrics_list <- get_multiple_lyrics("Taylor Swift", songs)
} # }
```
