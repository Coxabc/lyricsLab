# Calculate Lyrical Complexity

Computes comprehensive complexity metrics including vocabulary richness,
average word length, reading level, and syllable complexity. Prints a
clean summary to the console and returns results invisibly.

## Usage

``` r
complexity_score(lyrics_obj)
```

## Arguments

- lyrics_obj:

  Lyrics object from
  [`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)

## Value

Invisibly returns a list containing:

- vocabulary_size - Number of unique words

- total_words - Total word count

- type_token_ratio - Vocabulary richness (0-1)

- avg_word_length - Mean characters per word

- reading_level - Estimated grade level (Flesch-Kincaid)

- syllables_per_word - Average syllables per word

- interpretation - Text description of complexity

- complexity_score - Overall score (0-100)

- song - Track title

- artist - Artist name

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Kendrick Lamar", "HUMBLE.")
complexity_score(lyrics)

# Store result invisibly if needed
result <- complexity_score(lyrics)
} # }
```
