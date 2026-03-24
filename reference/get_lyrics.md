# Get Lyrics from Genius (Direct API + Simple Scraping)

Retrieves song lyrics by directly calling the Genius API and scraping
lyrics from the Genius website using rvest's html_text2().

## Usage

``` r
get_lyrics(artist, song, access_token = NULL)
```

## Arguments

- artist:

  Character string of artist name

- song:

  Character string of song title

- access_token:

  Genius API token. If NULL, uses GENIUS_API_TOKEN env var

## Value

A list of class "lyrics_lab" containing:

- lyrics - Character vector of lyrics (one element per line)

- metadata - List with song info

- structure - Data frame with detected sections

## Examples

``` r
if (FALSE) { # \dontrun{
# Set your token first
Sys.setenv(GENIUS_API_TOKEN = "your_token_here")

# Get lyrics
lyrics <- get_lyrics(artist = "Taylor Swift", song = "Anti-Hero")
} # }
```
