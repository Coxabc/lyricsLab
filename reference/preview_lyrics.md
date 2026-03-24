# Preview Lyrics

Shows metadata and the first few lines of a lyrics_lab object.

## Usage

``` r
preview_lyrics(x, n = 5)
```

## Arguments

- x:

  A lyrics_lab object

- n:

  Number of lines to show. Default 5

## Examples

``` r
if (FALSE) { # \dontrun{
lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
preview_lyrics(lyrics)
preview_lyrics(lyrics, n = 10)
} # }
```
