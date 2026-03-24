#' Analyze Playlist Lyrics
#'
#' Gets lyrics and analyzes all songs in a Spotify playlist.
#'
#' @param playlist_url Spotify playlist URL or ID
#' @param max_songs Maximum number of songs to analyze (default 50)
#' @param delay Delay between API calls in seconds (default 2)
#' @param token Spotify token (uses saved token if NULL)
#'
#' @return List with playlist tracks and lyrics analysis
#'
#' @export
#'
#' @examples
#' \dontrun{
#' analysis <- analyze_playlist(
#'   "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M",
#'   max_songs = 20
#' )
#' print(analysis)
#' plot_sentiment(analysis)
#' }
analyze_playlist <- function(playlist_url, max_songs = 50, delay = 2, token = NULL) {
 
  playlist_tracks <- get_playlist_tracks(playlist_url, token = token)
 
  if (nrow(playlist_tracks) == 0) {
    stop("No tracks found in playlist")
  }
 
  n_songs      <- min(max_songs, nrow(playlist_tracks))
  tracks       <- playlist_tracks[seq_len(n_songs), ]
  playlist_name <- tracks$playlist_name[1]
 
  message(sprintf("\nAnalyzing lyrics for %d songs...\n", n_songs))
 
  analyses <- list()
  failed   <- character()
 
  for (i in seq_len(n_songs)) {
    track_name  <- tracks$track_name[i]
    artist_name <- tracks$artist_name[i]
    clean_name  <- sub("\\s*-\\s*(Live|Acoustic).*$", "", track_name, ignore.case = TRUE)
 
    message(sprintf("[%d/%d] %s by %s", i, n_songs, track_name, artist_name))
 
    lyrics <- tryCatch(
      get_lyrics(artist_name, clean_name),
      error = function(e) {
        message(sprintf("  x Could not get lyrics: %s", e$message))
        NULL
      }
    )
 
    if (is.null(lyrics)) {
      failed <- c(failed, track_name)
      next
    }
 
    tryCatch({
      sent   <- sentiment_score(lyrics)
      comp   <- complexity_score(lyrics)
      themes <- theme_detection(lyrics)
 
      analyses[[track_name]] <- list(
        track_name               = track_name,
        artist_name              = artist_name,
        sentiment_score          = sent$score,
        sentiment_interpretation = sent$interpretation,
        complexity_score         = comp$complexity_score,
        reading_level            = comp$reading_level,
        vocabulary_size          = comp$vocabulary_size,
        dominant_theme           = themes$dominant_theme,
        lyrics                   = lyrics
      )
 
      message(sprintf("  + Sentiment: %.2f | Complexity: %.1f/100 | Theme: %s",
                      sent$score, comp$complexity_score, themes$dominant_theme))
    }, error = function(e) {
      message(sprintf("  x Analysis failed: %s", e$message))
      failed <<- c(failed, track_name)
    })
 
    if (i < n_songs) Sys.sleep(delay)
  }
 
  if (length(analyses) == 0) stop("No songs were successfully analyzed")
 
  summary_df <- do.call(rbind, lapply(analyses, function(a) {
    data.frame(
      track_name   = a$track_name,
      artist_name  = a$artist_name,
      sentiment    = a$sentiment_score,
      complexity   = a$complexity_score,
      reading_level = a$reading_level,
      theme        = a$dominant_theme,
      stringsAsFactors = FALSE
    )
  }))
 
  stats <- list(
    playlist_name     = playlist_name,
    total_tracks      = nrow(playlist_tracks),
    analyzed_tracks   = length(analyses),
    failed_tracks     = length(failed),
    avg_sentiment     = mean(summary_df$sentiment,     na.rm = TRUE),
    avg_complexity    = mean(summary_df$complexity,    na.rm = TRUE),
    avg_reading_level = mean(summary_df$reading_level, na.rm = TRUE),
    most_common_theme = names(which.max(table(summary_df$theme)))
  )
 
  message("\n=== PLAYLIST ANALYSIS COMPLETE ===")
  message(sprintf("Playlist: %s",            stats$playlist_name))
  message(sprintf("Analyzed: %d/%d tracks",  stats$analyzed_tracks, stats$total_tracks))
  message(sprintf("Avg sentiment: %.2f",     stats$avg_sentiment))
  message(sprintf("Avg complexity: %.1f/100", stats$avg_complexity))
  message(sprintf("Most common theme: %s",   stats$most_common_theme))
 
  if (length(failed) > 0) {
    message(sprintf("\nFailed to analyze %d tracks:", length(failed)))
    for (f in head(failed, 10)) message(sprintf("  - %s", f))
    if (length(failed) > 10) message(sprintf("  ... and %d more", length(failed) - 10))
  }
 
  list(
    playlist_info = playlist_tracks,
    analyses      = analyses,
    summary       = summary_df,
    stats         = stats,
    failed        = failed
  )
}



#' Plot Sentiment Distribution
#'
#' @param analysis_result Result from analyze_playlist()
#' @export
plot_sentiment <- function(analysis_result) {
  df <- analysis_result$summary
  avg <- mean(df$sentiment, na.rm = TRUE)
  playlist_name <- analysis_result$stats$playlist_name

  ggplot2::ggplot(df, ggplot2::aes(x = sentiment)) +
    ggplot2::geom_histogram(bins = 20, fill = "#1DB954", alpha = 0.7, color = "white") +
    ggplot2::geom_vline(xintercept = avg, color = "red", linetype = "dashed", linewidth = 1) +
    ggplot2::labs(
      title    = sprintf("Sentiment Distribution: %s", playlist_name),
      subtitle = sprintf("Average: %.2f", avg),
      x        = "Sentiment Score",
      y        = "Number of Songs"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14))
}


#' Plot Complexity Distribution
#'
#' @param analysis_result Result from analyze_playlist()
#' @export
plot_complexity <- function(analysis_result) {
  df <- analysis_result$summary
  avg <- mean(df$complexity, na.rm = TRUE)

  ggplot2::ggplot(df, ggplot2::aes(x = complexity)) +
    ggplot2::geom_histogram(bins = 20, fill = "#667eea", alpha = 0.7, color = "white") +
    ggplot2::geom_vline(xintercept = avg, color = "red", linetype = "dashed", linewidth = 1) +
    ggplot2::labs(
      title    = "Lyrical Complexity Distribution",
      subtitle = sprintf("Average: %.1f/100", avg),
      x        = "Complexity Score (0-100)",
      y        = "Number of Songs"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14))
}


#' Plot Theme Distribution
#'
#' @param analysis_result Result from analyze_playlist()
#' @export
plot_themes <- function(analysis_result) {
  df <- analysis_result$summary
  most_common <- analysis_result$stats$most_common_theme

  theme_counts <- as.data.frame(table(df$theme))
  names(theme_counts) <- c("Theme", "Count")
  theme_counts <- theme_counts[order(-theme_counts$Count), ]

  ggplot2::ggplot(theme_counts, ggplot2::aes(x = reorder(Theme, Count), y = Count)) +
    ggplot2::geom_bar(stat = "identity", fill = "#ff6b6b", alpha = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title    = "Lyrical Themes",
      subtitle = sprintf("Most common: %s", most_common),
      x        = "Theme",
      y        = "Number of Songs"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14))
}


#' Plot Sentiment vs Complexity Scatter
#'
#' @param analysis_result Result from analyze_playlist()
#' @export
plot_scatter <- function(analysis_result) {
  df <- analysis_result$summary

  ggplot2::ggplot(df, ggplot2::aes(x = complexity, y = sentiment)) +
    ggplot2::geom_point(color = "#1DB954", size = 3, alpha = 0.6) +
    ggplot2::geom_smooth(method = "lm", color = "#667eea", se = TRUE, alpha = 0.2) +
    ggplot2::labs(
      title = "Sentiment vs Complexity",
      x     = "Complexity Score",
      y     = "Sentiment Score"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14))
}


#' Plot Top 10 Most Complex Songs
#'
#' @param analysis_result Result from analyze_playlist()
#' @export
plot_top_complex <- function(analysis_result) {
  df <- analysis_result$summary
  top <- df[order(-df$complexity), ][seq_len(min(10, nrow(df))), ]
  top$label <- paste(top$track_name, "-", top$artist_name)

  ggplot2::ggplot(top, ggplot2::aes(x = reorder(label, complexity), y = complexity)) +
    ggplot2::geom_bar(stat = "identity", fill = "#764ba2", alpha = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Top 10 Most Complex Songs",
      x     = "",
      y     = "Complexity Score"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(face = "bold", size = 14),
      axis.text.y = ggplot2::element_text(size = 8)
    )
}