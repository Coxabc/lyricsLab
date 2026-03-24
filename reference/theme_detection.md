# Detect Themes in Lyrics

Identifies the main themes present in lyrics using keyword matching
across 23 theme categories. Prints a clean summary to the console and
returns results invisibly.

## Usage

``` r
theme_detection(lyrics_obj)
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

## Value

Invisibly returns a list containing:

- themes - Data frame of all themes with scores and percentages

- dominant_theme - Name of the top scoring theme

- dominant_score - Keyword match count for dominant theme

- summary - One-line text summary

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Adele", "Someone Like You")
theme_detection(lyrics)

# Store result invisibly if needed
result <- theme_detection(lyrics)
} # }
```
