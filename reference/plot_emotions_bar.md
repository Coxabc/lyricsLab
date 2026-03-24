# Plot Emotions

Creates a bar chart of the 8 NRC emotions detected in the lyrics.

## Usage

``` r
plot_emotions_bar(lyrics_obj, normalize = TRUE)
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

- normalize:

  Logical; normalize counts by total words? Default `TRUE`

## Value

Invisibly returns a ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Billie Eilish", "bad guy")
plot_emotions_bar(lyrics)
} # }
```
