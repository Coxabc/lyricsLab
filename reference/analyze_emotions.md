# Analyze Emotions Using NRC Lexicon

Detects presence of 8 emotions: joy, sadness, anger, fear, anticipation,
trust, surprise, disgust. Prints a clean summary to the console and
returns results invisibly.

## Usage

``` r
analyze_emotions(lyrics_obj, normalize = TRUE)
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

- normalize:

  Logical; normalize counts by total words? Default `TRUE`

## Value

Invisibly returns a list containing:

- emotions - Data frame with emotion counts and percentages

- dominant_emotion - Name of the top emotion

- summary - One-line text summary

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Billie Eilish", "bad guy")
analyze_emotions(lyrics)

# Store result invisibly if needed
result <- analyze_emotions(lyrics)
} # }
```
