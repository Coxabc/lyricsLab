# Plot Sentiment Arc

Creates a line chart showing how sentiment evolves line by line through
the song, with optional smoothing.

## Usage

``` r
plot_sentiment_arc(lyrics_obj, method = "afinn", smooth = TRUE)
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

- method:

  Sentiment method: `"afinn"`, `"bing"`, or `"nrc"`. Default `"afinn"`

- smooth:

  Logical; add smoothing line? Default `TRUE`

## Value

Invisibly returns a ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
plot_sentiment_arc(lyrics)

# Without smoothing
plot_sentiment_arc(lyrics, smooth = FALSE)
} # }
```
