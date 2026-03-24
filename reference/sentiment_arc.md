# Calculate Sentiment Arc

Calculates sentiment scores for each line of lyrics and prints a clean
summary to the console. Use
[`plot_sentiment_arc()`](https://coxabc.github.io/lyricsLab/reference/plot_sentiment_arc.md)
to visualize.

## Usage

``` r
sentiment_arc(lyrics_obj, method = "afinn")
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

- method:

  Sentiment method: `"afinn"`, `"bing"`, or `"nrc"`. Default `"afinn"`

## Value

Invisibly returns a list containing:

- scores - Data frame with line-by-line sentiment scores

- mean_sentiment - Mean sentiment across all lines

- median_sentiment - Median sentiment

- range - Min and max sentiment scores

- sd - Standard deviation

- trajectory - How sentiment changes through the song

- positive_lines - Count of positive lines

- negative_lines - Count of negative lines

- neutral_lines - Count of neutral lines

- song - Track title

- artist - Artist name

- method - Method used

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
sentiment_arc(lyrics)

# Store result invisibly if needed
result <- sentiment_arc(lyrics)
} # }
```
