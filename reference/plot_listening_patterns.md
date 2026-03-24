# Visualize Listening Patterns Over Time

Creates a plot of when you listen to music by hour, day, or week. Prints
directly to the graphics device.

## Usage

``` r
plot_listening_patterns(history_df, type = "hourly")
```

## Arguments

- history_df:

  Data frame from
  [`get_recently_played()`](https://coxabc.github.io/lyricsLab/reference/get_recently_played.md)

- type:

  Type of visualization: `"hourly"`, `"daily"`, or `"weekly"`. Default
  `"hourly"`

## Value

Invisibly returns a ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
history <- get_recently_played(n_total = 50)
plot_listening_patterns(history, type = "hourly")
plot_listening_patterns(history, type = "daily")
plot_listening_patterns(history, type = "weekly")
} # }
```
