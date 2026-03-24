# Analyzing a Single Song

This vignette walks through a complete analysis of a single song — from
fetching lyrics to plotting sentiment, emotions, complexity, and themes.

## Setup

Set your Genius API token before starting. You can get one at
<https://genius.com/api-clients>.

``` r
Sys.setenv(GENIUS_API_TOKEN = "your_token_here")
library(lyricsLab)
```

## Fetching lyrics

[`get_lyrics()`](https://coxabc.github.io/lyricsLab/reference/get_lyrics.md)
searches Genius for the song, scrapes the lyrics page, and returns a
`lyrics_lab` object containing the lyrics, metadata, and detected song
structure.

``` r
lyrics <- get_lyrics("Billie Eilish", "bad guy")
```

Use
[`preview_lyrics()`](https://coxabc.github.io/lyricsLab/reference/preview_lyrics.md)
to check what was retrieved:

``` r
preview_lyrics(lyrics)
#> Song:     bad guy
#> Artist:   Billie Eilish
#> Album:    WHEN WE ALL FALL ASLEEP, WHERE DO WE GO?
#> Lines:    47
#> URL:      https://genius.com/...
#> Sections: verse, chorus, outro
#>
#> duh
#> I'm the bad guy
#> duh
#> I'm the bad guy
#> ...
```

Use
[`view_lyrics()`](https://coxabc.github.io/lyricsLab/reference/view_lyrics.md)
to print everything:

``` r
view_lyrics(lyrics)
```

## Sentiment

### Overall score

[`sentiment_score()`](https://coxabc.github.io/lyricsLab/reference/sentiment_score.md)
computes a single score for the whole song using the AFINN lexicon (or
bing/nrc if you prefer). It prints a summary and returns results
invisibly.

``` r
result <- sentiment_score(lyrics)
#>
#> === Sentiment: bad guy by Billie Eilish ===
#>   Method:          afinn
#>   Score:           -0.34
#>   Normalized:      46.6 / 100
#>   Interpretation:  Neutral - balanced emotional tone
#>   Positive lines:  19.1%
#>   Negative lines:  25.5%
```

Switch methods with the `method` argument:

``` r
sentiment_score(lyrics, method = "bing")
sentiment_score(lyrics, method = "nrc")
```

### Sentiment arc

[`sentiment_arc()`](https://coxabc.github.io/lyricsLab/reference/sentiment_arc.md)
scores every line individually and describes how sentiment shifts
through the song:

``` r
arc <- sentiment_arc(lyrics)
#>
#> === Sentiment Arc: bad guy by Billie Eilish ===
#>   Method:          afinn
#>   Mean sentiment:  -0.34
#>   Trajectory:      Maintains consistent tone
#>   Positive lines:  9
#>   Negative lines:  12
#>   Neutral lines:   26
```

Visualize the arc with
[`plot_sentiment_arc()`](https://coxabc.github.io/lyricsLab/reference/plot_sentiment_arc.md):

``` r
plot_sentiment_arc(lyrics)
```

Each point is one lyric line, coloured green (positive) through red
(negative). The smoothing line shows the overall trajectory. Turn it off
with `smooth = FALSE`:

``` r
plot_sentiment_arc(lyrics, smooth = FALSE)
```

### Positive/negative ratio

``` r
positive_negative_ratio(lyrics)
#>
#> === Positive/Negative Ratio: bad guy by Billie Eilish ===
#>   Ratio:           0.75:1 (positive:negative)
#>   Interpretation:  Balanced
#>   Positive lines:  9  (19.1%)
#>   Negative lines:  12 (25.5%)
#>   Neutral lines:   26 (55.3%)
```

## Emotions

[`analyze_emotions()`](https://coxabc.github.io/lyricsLab/reference/analyze_emotions.md)
uses the NRC lexicon to detect eight emotions: anger, anticipation,
disgust, fear, joy, sadness, surprise, and trust.

``` r
analyze_emotions(lyrics)
#>
#> === Emotions: bad guy by Billie Eilish ===
#>   anticipation   3 words (0.51%)
#>   joy            2 words (0.34%)
#>   trust          2 words (0.34%)
#>   anger          1 words (0.17%)
#>   ...
#>   Dominant emotion: anticipation
```

Two plot options — bar chart or radar/web chart:

``` r
plot_emotions_bar(lyrics)
plot_emotions_web(lyrics)
```

The radar chart is useful for comparing the emotional “shape” of songs
side by side visually.

## Complexity

[`complexity_score()`](https://coxabc.github.io/lyricsLab/reference/complexity_score.md)
measures vocabulary richness, average word length, syllables per word,
and estimates a Flesch-Kincaid reading level, combining them into a
single 0–100 complexity score.

``` r
complexity_score(lyrics)
#>
#> === Complexity: bad guy by Billie Eilish ===
#>   Vocabulary size:     106 unique / 210 total words
#>   Vocabulary richness: 0.505
#>   Avg word length:     3.81 characters
#>   Syllables per word:  1.29
#>   Reading level:       3.2 (grade)
#>   Complexity score:    24.6 / 100
#>   Interpretation:      Elementary level - very simple vocabulary
```

A high type-token ratio (unique/total) indicates more varied vocabulary.
Reading level is estimated grade level — elementary through graduate.

## Themes

[`theme_detection()`](https://coxabc.github.io/lyricsLab/reference/theme_detection.md)
matches lyrics against keyword lists across 23 theme categories and
shows the top matches:

``` r
theme_detection(lyrics)
#>
#> === Themes: bad guy by Billie Eilish ===
#>   Lust/Desire            4 matches (22.2%)
#>   Jealousy               3 matches (16.7%)
#>   Rebellion              3 matches (16.7%)
#>   Empowerment            3 matches (16.7%)
#>   Time/Change            2 matches (11.1%)
#>
#>   Dominant theme: Lust/Desire
```

Plot the theme breakdown:

``` r
plot_themes(lyrics)
```

## Storing results

All analysis functions print to the console and return results
invisibly. Capture them by assigning to a variable:

``` r
sent   <- sentiment_score(lyrics)
comp   <- complexity_score(lyrics)
themes <- theme_detection(lyrics)
emo    <- analyze_emotions(lyrics)
```
