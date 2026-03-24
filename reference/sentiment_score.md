# Calculate Overall Sentiment Score

Computes a single sentiment score for entire lyrics using the syuzhet
package. Prints a clean summary to the console and returns results
invisibly.

## Usage

``` r
sentiment_score(lyrics_obj, method = "afinn")
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

- method:

  Sentiment method: `"afinn"`, `"bing"`, or `"nrc"`. Default `"afinn"`

## Value

Invisibly returns a list containing:

- score - Raw sentiment score

- normalized_score - Score normalized to 0-100

- interpretation - Text description of sentiment

- method - Method used

- song - Track title

- artist - Artist name

- positive_ratio - Proportion of positive lines

- negative_ratio - Proportion of negative lines

- scores - Per-line sentiment scores

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Adele", "Someone Like You")
sentiment_score(lyrics)

# Use a different method
sentiment_score(lyrics, method = "bing")
} # }
```
