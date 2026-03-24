# Calculate Positive/Negative Ratio

Computes the balance between positive and negative sentiment lines.
Prints a clean summary to the console and returns results invisibly.

## Usage

``` r
positive_negative_ratio(lyrics_obj)
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

## Value

Invisibly returns a list containing:

- ratio - Positive to negative ratio (Inf if no negative lines)

- ratio_text - Human-readable ratio string

- interpretation - Text description of balance

- positive_lines - Count of positive lines

- negative_lines - Count of negative lines

- neutral_lines - Count of neutral lines

- positive_percentage - Percentage of positive lines

- negative_percentage - Percentage of negative lines

- neutral_percentage - Percentage of neutral lines

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Pharrell Williams", "Happy")
positive_negative_ratio(lyrics)
} # }
```
