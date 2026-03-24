#' Visualize Listening Patterns Over Time
#'
#' Creates a plot of when you listen to music by hour, day, or week.
#' Prints directly to the graphics device.
#'
#' @param history_df Data frame from \code{get_recently_played()}
#' @param type Type of visualization: \code{"hourly"}, \code{"daily"}, or \code{"weekly"}.
#'   Default \code{"hourly"}
#'
#' @return Invisibly returns a ggplot object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' history <- get_recently_played(n_total = 50)
#' plot_listening_patterns(history, type = "hourly")
#' plot_listening_patterns(history, type = "daily")
#' plot_listening_patterns(history, type = "weekly")
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_bar geom_line geom_point scale_x_continuous
#' scale_fill_gradient theme_minimal theme element_text labs
plot_listening_patterns <- function(history_df, type = "hourly") {

  if (!type %in% c("hourly", "daily", "weekly")) {
    stop("type must be 'hourly', 'daily', or 'weekly'")
  }

  history_df$hour    <- as.numeric(format(history_df$played_at, "%H"))
  history_df$weekday <- weekdays(history_df$played_at)
  history_df$date    <- as.Date(history_df$played_at)

  if (type == "hourly") {
    hourly_counts <- aggregate(track_name ~ hour, data = history_df, FUN = length)
    names(hourly_counts) <- c("hour", "plays")

    p <- ggplot2::ggplot(hourly_counts, ggplot2::aes(x = hour, y = plays)) +
      ggplot2::geom_bar(stat = "identity", fill = "#1DB954", alpha = 0.8) +
      ggplot2::scale_x_continuous(breaks = 0:23, labels = sprintf("%02d:00", 0:23)) +
      ggplot2::theme_minimal(base_size = 14) +
      ggplot2::theme(
        plot.title       = ggplot2::element_text(face = "bold", size = 16),
        axis.text.x      = ggplot2::element_text(angle = 45, hjust = 1),
        panel.grid.minor = ggplot2::element_blank()
      ) +
      ggplot2::labs(
        title    = "When Do You Listen to Music?",
        subtitle = sprintf("Based on %d plays", nrow(history_df)),
        x        = "Hour of Day",
        y        = "Number of Plays"
      )

  } else if (type == "daily") {
    daily_counts <- aggregate(track_name ~ date, data = history_df, FUN = length)
    names(daily_counts) <- c("date", "plays")

    p <- ggplot2::ggplot(daily_counts, ggplot2::aes(x = date, y = plays)) +
      ggplot2::geom_line(color = "#1DB954", linewidth = 1.2) +
      ggplot2::geom_point(color = "#1DB954", size = 2) +
      ggplot2::theme_minimal(base_size = 14) +
      ggplot2::theme(
        plot.title       = ggplot2::element_text(face = "bold", size = 16),
        panel.grid.minor = ggplot2::element_blank()
      ) +
      ggplot2::labs(
        title    = "Listening Activity Over Time",
        subtitle = sprintf("%s to %s", min(daily_counts$date), max(daily_counts$date)),
        x        = "Date",
        y        = "Plays per Day"
      )

  } else {
    history_df$weekday <- factor(history_df$weekday,
                                  levels = c("Monday", "Tuesday", "Wednesday",
                                             "Thursday", "Friday", "Saturday", "Sunday"))
    weekly_counts <- aggregate(track_name ~ weekday, data = history_df, FUN = length)
    names(weekly_counts) <- c("weekday", "plays")

    p <- ggplot2::ggplot(weekly_counts, ggplot2::aes(x = weekday, y = plays, fill = plays)) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::scale_fill_gradient(low = "#4ECDC4", high = "#1DB954") +
      ggplot2::theme_minimal(base_size = 14) +
      ggplot2::theme(
        plot.title       = ggplot2::element_text(face = "bold", size = 16),
        axis.text.x      = ggplot2::element_text(angle = 45, hjust = 1),
        panel.grid.minor = ggplot2::element_blank(),
        legend.position  = "none"
      ) +
      ggplot2::labs(
        title    = "What Day Do You Listen Most?",
        subtitle = sprintf("Based on %d plays", nrow(history_df)),
        x        = NULL,
        y        = "Number of Plays"
      )
  }

  print(p)
  invisible(p)
}



#' Calculate Listening Diversity
#'
#' Measures how diverse your listening habits are using Shannon entropy.
#' Prints a clean summary to the console and returns results invisibly.
#'
#' @param history_df Data frame from \code{get_recently_played()}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item unique_artists - Number of unique artists
#'     \item unique_tracks - Number of unique tracks
#'     \item total_plays - Total number of plays
#'     \item top_artist - Most played artist
#'     \item top_artist_percentage - Percentage of plays by top artist
#'     \item diversity_score - Score from 0-100 (higher = more diverse)
#'     \item interpretation - Text description of diversity
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' history <- get_recently_played(n_total = 500)
#' calculate_listening_diversity(history)
#' 
#' playlist <- get_playlist_tracks("https://open.spotify.com/playlist/123abc")
#' calculate_listening_diversity(playlist)
#' }
calculate_listening_diversity <- function(history_df) {

  unique_artists  <- length(unique(history_df$artist_name))
  unique_tracks   <- length(unique(history_df$track_name))
  total_plays     <- nrow(history_df)

  artist_counts   <- table(history_df$artist_name)
  top_artist_pct  <- (max(artist_counts) / total_plays) * 100

  artist_props    <- artist_counts / sum(artist_counts)
  shannon_entropy <- -sum(artist_props * log(artist_props))
  max_entropy     <- log(length(artist_counts))
  diversity_score <- (shannon_entropy / max_entropy) * 100

  interpretation <- if (diversity_score > 80) {
    "Very diverse - you explore many different artists"
  } else if (diversity_score > 60) {
    "Moderately diverse - good mix of variety and favorites"
  } else if (diversity_score > 40) {
    "Somewhat focused - you have clear favorites"
  } else {
    "Highly focused - you mainly listen to a few artists"
  }

  cat(sprintf("\n=== Listening Diversity ===\n"))
  cat(sprintf("  Unique artists:    %d\n", unique_artists))
  cat(sprintf("  Unique tracks:     %d\n", unique_tracks))
  cat(sprintf("  Total plays:       %d\n", total_plays))
  cat(sprintf("  Top artist:        %s (%.1f%% of plays)\n",
              names(which.max(artist_counts)), top_artist_pct))
  cat(sprintf("  Diversity score:   %.1f / 100\n", diversity_score))
  cat(sprintf("  Interpretation:    %s\n\n", interpretation))

  result <- list(
    unique_artists        = unique_artists,
    unique_tracks         = unique_tracks,
    total_plays           = total_plays,
    top_artist            = names(which.max(artist_counts)),
    top_artist_percentage = round(top_artist_pct, 1),
    diversity_score       = round(diversity_score, 1),
    interpretation        = interpretation
  )

  invisible(result)
}

