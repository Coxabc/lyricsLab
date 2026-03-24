# Plot Lyrical Themes

Creates a bar chart of the top theme keyword matches found in the
lyrics. Only themes with at least one match are shown, up to a maximum
of 10.

## Usage

``` r
plot_themes(analysis_result)

plot_themes(analysis_result)
```

## Arguments

- analysis_result:

  Result from analyze_playlist()

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

## Value

Invisibly returns a ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Adele", "Someone Like You")
plot_themes(lyrics)
} # }
```
