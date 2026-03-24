#' Calculate Sentiment Arc
#'
#' Calculates sentiment scores for each line of lyrics and prints a clean
#' summary to the console. Use \code{plot_sentiment_arc()} to visualize.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#' @param method Sentiment method: \code{"afinn"}, \code{"bing"}, or \code{"nrc"}.
#'   Default \code{"afinn"}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item scores - Data frame with line-by-line sentiment scores
#'     \item mean_sentiment - Mean sentiment across all lines
#'     \item median_sentiment - Median sentiment
#'     \item range - Min and max sentiment scores
#'     \item sd - Standard deviation
#'     \item trajectory - How sentiment changes through the song
#'     \item positive_lines - Count of positive lines
#'     \item negative_lines - Count of negative lines
#'     \item neutral_lines - Count of neutral lines
#'     \item song - Track title
#'     \item artist - Artist name
#'     \item method - Method used
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
#' sentiment_arc(lyrics)
#'
#' # Store result invisibly if needed
#' result <- sentiment_arc(lyrics)
#' }
#'
#' @importFrom syuzhet get_sentiment
sentiment_arc <- function(lyrics_obj, method = "afinn") {

  validate_lyrics(lyrics_obj)

  lyrics    <- lyrics_obj$lyrics
  structure <- lyrics_obj$structure

  if (length(lyrics) != nrow(structure)) {
    warning(sprintf("Lyrics length (%d) doesn't match structure (%d). Using structure.",
                    length(lyrics), nrow(structure)))
    lyrics <- structure$lyric
  }

  message(sprintf("Calculating sentiment scores using %s method...", method))

  if (!method %in% c("afinn", "bing", "nrc")) {
    stop("Method must be 'afinn', 'bing', or 'nrc'")
  }

  scores <- syuzhet::get_sentiment(lyrics, method = method)

  sentiment_df <- data.frame(
    line_number = seq_along(lyrics),
    lyric       = lyrics,
    sentiment   = scores,
    section     = structure$section,
    stringsAsFactors = FALSE
  )

  trajectory     <- determine_trajectory(scores)
  positive_lines <- sum(scores > 0, na.rm = TRUE)
  negative_lines <- sum(scores < 0, na.rm = TRUE)
  neutral_lines  <- sum(scores == 0, na.rm = TRUE)
  mean_sent      <- mean(scores, na.rm = TRUE)

  message("✓ Sentiment arc complete!")

  cat(sprintf("\n=== Sentiment Arc: %s by %s ===\n",
              lyrics_obj$metadata$title, lyrics_obj$metadata$artist))
  cat(sprintf("  Method:          %s\n", method))
  cat(sprintf("  Mean sentiment:  %.2f\n", mean_sent))
  cat(sprintf("  Median:          %.2f\n", median(scores, na.rm = TRUE)))
  cat(sprintf("  Std deviation:   %.2f\n", sd(scores, na.rm = TRUE)))
  cat(sprintf("  Range:           %.2f to %.2f\n",
              min(scores, na.rm = TRUE), max(scores, na.rm = TRUE)))
  cat(sprintf("  Trajectory:      %s\n", trajectory))
  cat(sprintf("  Positive lines:  %d\n", positive_lines))
  cat(sprintf("  Negative lines:  %d\n", negative_lines))
  cat(sprintf("  Neutral lines:   %d\n\n", neutral_lines))

  result <- list(
    scores         = sentiment_df,
    mean_sentiment = mean_sent,
    median_sentiment = median(scores, na.rm = TRUE),
    range          = range(scores, na.rm = TRUE),
    sd             = sd(scores, na.rm = TRUE),
    trajectory     = trajectory,
    positive_lines = positive_lines,
    negative_lines = negative_lines,
    neutral_lines  = neutral_lines,
    song           = lyrics_obj$metadata$title,
    artist         = lyrics_obj$metadata$artist,
    method         = method
  )

  invisible(result)
}


#' Plot Sentiment Arc
#'
#' Creates a line chart showing how sentiment evolves line by line
#' through the song, with optional smoothing.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#' @param method Sentiment method: \code{"afinn"}, \code{"bing"}, or \code{"nrc"}.
#'   Default \code{"afinn"}
#' @param smooth Logical; add smoothing line? Default \code{TRUE}
#'
#' @return Invisibly returns a ggplot object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
#' plot_sentiment_arc(lyrics)
#'
#' # Without smoothing
#' plot_sentiment_arc(lyrics, smooth = FALSE)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_point geom_smooth geom_hline
#' scale_color_gradient2 theme_minimal theme element_text element_blank labs
#' @importFrom syuzhet get_sentiment
plot_sentiment_arc <- function(lyrics_obj, method = "afinn", smooth = TRUE) {

  result <- sentiment_arc(lyrics_obj, method = method)

  p <- ggplot2::ggplot(result$scores, ggplot2::aes(x = line_number, y = sentiment)) +
    ggplot2::geom_line(color = "#1DB954", linewidth = 1.2, alpha = 0.8) +
    ggplot2::geom_point(ggplot2::aes(color = sentiment), size = 3, alpha = 0.7) +
    ggplot2::scale_color_gradient2(
      low      = "#FF6B6B",
      mid      = "#FFD93D",
      high     = "#1DB954",
      midpoint = 0,
      name     = "Sentiment"
    ) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5, linewidth = 0.8) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle    = ggplot2::element_text(color = "gray40"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "right"
    ) +
    ggplot2::labs(
      title    = sprintf("Sentiment Arc: \"%s\"", result$song),
      subtitle = sprintf("by %s | %s | Mean: %.2f",
                         result$artist, result$trajectory, result$mean_sentiment),
      x        = "Line Number",
      y        = "Sentiment Score",
      caption  = sprintf("Method: %s | %d positive, %d negative, %d neutral lines",
                         result$method,
                         result$positive_lines,
                         result$negative_lines,
                         result$neutral_lines)
    )

  if (smooth) {
    p <- p + ggplot2::geom_smooth(se = TRUE, color = "#191414",
                                   linewidth = 0.8, alpha = 0.2)
  }

  print(p)
  invisible(p)
}


#' Calculate Overall Sentiment Score
#'
#' Computes a single sentiment score for entire lyrics using the syuzhet
#' package. Prints a clean summary to the console and returns results invisibly.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#' @param method Sentiment method: \code{"afinn"}, \code{"bing"}, or \code{"nrc"}.
#'   Default \code{"afinn"}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item score - Raw sentiment score
#'     \item normalized_score - Score normalized to 0-100
#'     \item interpretation - Text description of sentiment
#'     \item method - Method used
#'     \item song - Track title
#'     \item artist - Artist name
#'     \item positive_ratio - Proportion of positive lines
#'     \item negative_ratio - Proportion of negative lines
#'     \item scores - Per-line sentiment scores
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Adele", "Someone Like You")
#' sentiment_score(lyrics)
#'
#' # Use a different method
#' sentiment_score(lyrics, method = "bing")
#' }
#'
#' @importFrom syuzhet get_sentiment
sentiment_score <- function(lyrics_obj, method = "afinn") {

  validate_lyrics(lyrics_obj)

  scores  <- syuzhet::get_sentiment(lyrics_obj$lyrics, method = method)
  overall <- mean(scores, na.rm = TRUE)

  if (method == "afinn") {
    normalized <- ((overall + 5) / 10) * 100
  } else {
    normalized <- ((overall + 1) / 2) * 100
  }
  normalized <- max(0, min(100, normalized))

  interpretation <- if (overall > 1) {
    "Very positive - uplifting and joyful"
  } else if (overall > 0.3) {
    "Positive - optimistic and hopeful"
  } else if (overall > -0.3) {
    "Neutral - balanced emotional tone"
  } else if (overall > -1) {
    "Negative - melancholy or sad"
  } else {
    "Very negative - dark or sorrowful"
  }

  cat(sprintf("\n=== Sentiment: %s by %s ===\n",
              lyrics_obj$metadata$title, lyrics_obj$metadata$artist))
  cat(sprintf("  Method:          %s\n", method))
  cat(sprintf("  Score:           %.2f\n", overall))
  cat(sprintf("  Normalized:      %.1f / 100\n", normalized))
  cat(sprintf("  Interpretation:  %s\n", interpretation))
  cat(sprintf("  Positive lines:  %.1f%%\n", (sum(scores > 0) / length(scores)) * 100))
  cat(sprintf("  Negative lines:  %.1f%%\n\n", (sum(scores < 0) / length(scores)) * 100))

  result <- list(
    score            = overall,
    normalized_score = normalized,
    interpretation   = interpretation,
    method           = method,
    song             = lyrics_obj$metadata$title,
    artist           = lyrics_obj$metadata$artist,
    positive_ratio   = sum(scores > 0) / length(scores),
    negative_ratio   = sum(scores < 0) / length(scores),
    scores           = scores
  )

  invisible(result)
}


#' Analyze Emotions Using NRC Lexicon
#'
#' Detects presence of 8 emotions: joy, sadness, anger, fear,
#' anticipation, trust, surprise, disgust. Prints a clean summary
#' to the console and returns results invisibly.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#' @param normalize Logical; normalize counts by total words? Default \code{TRUE}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item emotions - Data frame with emotion counts and percentages
#'     \item dominant_emotion - Name of the top emotion
#'     \item summary - One-line text summary
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Billie Eilish", "bad guy")
#' analyze_emotions(lyrics)
#'
#' # Store result invisibly if needed
#' result <- analyze_emotions(lyrics)
#' }
#'
#' @importFrom syuzhet get_nrc_sentiment
analyze_emotions <- function(lyrics_obj, normalize = TRUE) {

  validate_lyrics(lyrics_obj)

  message("Analyzing emotions using NRC lexicon...")

  full_text <- paste(lyrics_obj$lyrics, collapse = " ")
  emotions  <- syuzhet::get_nrc_sentiment(full_text)

  emotion_cols <- c("anger", "anticipation", "disgust", "fear",
                    "joy", "sadness", "surprise", "trust")
  emotions <- emotions[, emotion_cols, drop = FALSE]

  emotions_long <- data.frame(
    emotion = names(emotions),
    count   = as.numeric(emotions[1, ]),
    stringsAsFactors = FALSE
  )

  if (normalize) {
    total_words <- length(strsplit(full_text, "\\s+")[[1]])
    emotions_long$percentage <- round((emotions_long$count / total_words) * 100, 2)
  }

  emotions_long    <- emotions_long[order(-emotions_long$count), ]
  dominant_emotion <- as.character(emotions_long$emotion[1])
  dominant_count   <- emotions_long$count[1]

  message("✓ Emotion analysis complete!")

  cat(sprintf("\n=== Emotions: %s by %s ===\n",
              lyrics_obj$metadata$title, lyrics_obj$metadata$artist))
  for (i in seq_len(nrow(emotions_long))) {
    if (normalize) {
      cat(sprintf("  %-14s %d words (%.2f%%)\n",
                  emotions_long$emotion[i],
                  emotions_long$count[i],
                  emotions_long$percentage[i]))
    } else {
      cat(sprintf("  %-14s %d words\n",
                  emotions_long$emotion[i],
                  emotions_long$count[i]))
    }
  }
  cat(sprintf("\n  Dominant emotion: %s\n\n", dominant_emotion))

  result <- list(
    emotions         = emotions_long,
    dominant_emotion = dominant_emotion,
    summary          = sprintf("Dominant emotion: %s (%d words)",
                               dominant_emotion, dominant_count)
  )

  invisible(result)
}


#' Plot Emotions
#'
#' Creates a bar chart of the 8 NRC emotions detected in the lyrics.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#' @param normalize Logical; normalize counts by total words? Default \code{TRUE}
#'
#' @return Invisibly returns a ggplot object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Billie Eilish", "bad guy")
#' plot_emotions_bar(lyrics)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_col coord_flip scale_fill_brewer
#' theme_minimal theme element_text element_blank labs
#' @importFrom syuzhet get_nrc_sentiment
plot_emotions_bar <- function(lyrics_obj, normalize = TRUE) {

  result       <- analyze_emotions(lyrics_obj, normalize = normalize)
  emotions_long <- result$emotions
  emotions_long$emotion <- factor(emotions_long$emotion,
                                   levels = rev(emotions_long$emotion))

  p <- ggplot2::ggplot(emotions_long,
                       ggplot2::aes(x = emotion, y = count, fill = emotion)) +
    ggplot2::geom_col(show.legend = FALSE, width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_brewer(palette = "Set3") +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title         = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle      = ggplot2::element_text(color = "gray40"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank()
    ) +
    ggplot2::labs(
      title    = sprintf("Emotional Profile: \"%s\"", lyrics_obj$metadata$title),
      subtitle = sprintf("by %s | Dominant: %s",
                         lyrics_obj$metadata$artist, result$dominant_emotion),
      x        = NULL,
      y        = "Word Count"
    )

  print(p)
  invisible(p)
}

#' Plot Emotions as Radar/Web Chart
#'
#' Creates a radar chart visualizing the 8 NRC emotions detected in the lyrics.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#' @param normalize Logical; normalize counts by total words? Default \code{TRUE}
#'
#' @return Invisibly returns a ggplot object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Billie Eilish", "bad guy")
#' plot_emotions_web(lyrics)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_polygon geom_line geom_point coord_polar
#' scale_y_continuous theme_minimal theme element_text element_blank labs
#' @importFrom syuzhet get_nrc_sentiment
plot_emotions_web <- function(lyrics_obj, normalize = TRUE) {

  result        <- analyze_emotions(lyrics_obj, normalize = normalize)
  emotions_long <- result$emotions

  # Normalize scores to 0-1 for radar
  max_count <- max(emotions_long$count, na.rm = TRUE)
  if (max_count == 0) {
    message("No emotions detected — cannot plot radar chart.")
    return(invisible(NULL))
  }

  emotions_long$scaled <- emotions_long$count / max_count

  # Radar charts need the first row repeated at the end to close the polygon
  n         <- nrow(emotions_long)
  plot_data <- rbind(emotions_long, emotions_long[1, ])
  plot_data$angle_index <- 1:nrow(plot_data)

  # Compute x/y coordinates manually for a polygon radar
  angles <- seq(0, 2 * pi, length.out = n + 1)[-(n + 1)]
  coords <- data.frame(
    emotion = emotions_long$emotion,
    x       = emotions_long$scaled * sin(angles),
    y       = emotions_long$scaled * cos(angles),
    scaled  = emotions_long$scaled
  )

  # Close the polygon
  polygon_coords <- rbind(coords, coords[1, ])

  # Grid rings
  grid_levels <- c(0.25, 0.5, 0.75, 1.0)
  grid_lines  <- do.call(rbind, lapply(grid_levels, function(r) {
    data.frame(
      x     = r * sin(c(angles, angles[1])),
      y     = r * cos(c(angles, angles[1])),
      level = r
    )
  }))

  # Spoke endpoints for each emotion label
  label_r <- 1.18
  label_coords <- data.frame(
    emotion = emotions_long$emotion,
    x       = label_r * sin(angles),
    y       = label_r * cos(angles)
  )

  p <- ggplot2::ggplot() +
    # Grid rings
    ggplot2::geom_polygon(
      data = grid_lines,
      ggplot2::aes(x = x, y = y, group = level),
      fill = NA, color = "gray85", linewidth = 0.4
    ) +
    # Spokes
    ggplot2::geom_segment(
      data = coords,
      ggplot2::aes(x = 0, y = 0, xend = sin(angles) * 1.05, yend = cos(angles) * 1.05),
      color = "gray80", linewidth = 0.4
    ) +
    # Filled radar polygon
    ggplot2::geom_polygon(
      data = polygon_coords,
      ggplot2::aes(x = x, y = y),
      fill = "#667eea", alpha = 0.3, color = "#667eea", linewidth = 1.2
    ) +
    # Points at each emotion vertex
    ggplot2::geom_point(
      data = coords,
      ggplot2::aes(x = x, y = y),
      color = "#667eea", size = 4
    ) +
    # Emotion labels
    ggplot2::geom_text(
      data = label_coords,
      ggplot2::aes(x = x, y = y, label = emotion),
      size = 4.5, fontface = "bold", color = "gray20"
    ) +
    # Grid ring labels
    ggplot2::annotate(
      "text", x = 0, y = grid_levels, 
      label = paste0(round(grid_levels * 100), "%"),
      size = 3, color = "gray60", vjust = -0.3
    ) +
    ggplot2::coord_equal() +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = 16,
                                             hjust = 0.5, margin = ggplot2::margin(b = 5)),
      plot.subtitle = ggplot2::element_text(color = "gray40", size = 12,
                                             hjust = 0.5, margin = ggplot2::margin(b = 10)),
      plot.margin   = ggplot2::margin(20, 20, 20, 20)
    ) +
    ggplot2::labs(
      title    = sprintf("Emotional Profile: \"%s\"", lyrics_obj$metadata$title),
      subtitle = sprintf("by %s | Dominant: %s",
                         lyrics_obj$metadata$artist, result$dominant_emotion)
    )

  print(p)
  invisible(p)
}

#' Calculate Positive/Negative Ratio
#'
#' Computes the balance between positive and negative sentiment lines.
#' Prints a clean summary to the console and returns results invisibly.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item ratio - Positive to negative ratio (Inf if no negative lines)
#'     \item ratio_text - Human-readable ratio string
#'     \item interpretation - Text description of balance
#'     \item positive_lines - Count of positive lines
#'     \item negative_lines - Count of negative lines
#'     \item neutral_lines - Count of neutral lines
#'     \item positive_percentage - Percentage of positive lines
#'     \item negative_percentage - Percentage of negative lines
#'     \item neutral_percentage - Percentage of neutral lines
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Pharrell Williams", "Happy")
#' positive_negative_ratio(lyrics)
#' }
#'
#' @importFrom syuzhet get_sentiment
positive_negative_ratio <- function(lyrics_obj) {

  validate_lyrics(lyrics_obj)

  scores         <- syuzhet::get_sentiment(lyrics_obj$lyrics, method = "afinn")
  positive_count <- sum(scores > 0, na.rm = TRUE)
  negative_count <- sum(scores < 0, na.rm = TRUE)
  neutral_count  <- sum(scores == 0, na.rm = TRUE)
  total          <- length(scores)

  if (negative_count == 0) {
    ratio      <- Inf
    ratio_text <- "All positive (no negative lines)"
  } else {
    ratio      <- positive_count / negative_count
    ratio_text <- sprintf("%.2f:1 (positive:negative)", ratio)
  }

  interpretation <- if (ratio > 3) {
    "Overwhelmingly positive"
  } else if (ratio > 1.5) {
    "Mostly positive"
  } else if (ratio > 0.67) {
    "Balanced"
  } else if (ratio > 0.33) {
    "Mostly negative"
  } else {
    "Overwhelmingly negative"
  }

  cat(sprintf("\n=== Positive/Negative Ratio: %s by %s ===\n",
              lyrics_obj$metadata$title, lyrics_obj$metadata$artist))
  cat(sprintf("  Ratio:           %s\n", ratio_text))
  cat(sprintf("  Interpretation:  %s\n", interpretation))
  cat(sprintf("  Positive lines:  %d (%.1f%%)\n",
              positive_count, (positive_count / total) * 100))
  cat(sprintf("  Negative lines:  %d (%.1f%%)\n",
              negative_count, (negative_count / total) * 100))
  cat(sprintf("  Neutral lines:   %d (%.1f%%)\n\n",
              neutral_count, (neutral_count / total) * 100))

  result <- list(
    ratio               = if (ratio == Inf) Inf else round(ratio, 2),
    ratio_text          = ratio_text,
    interpretation      = interpretation,
    positive_lines      = positive_count,
    negative_lines      = negative_count,
    neutral_lines       = neutral_count,
    positive_percentage = (positive_count / total) * 100,
    negative_percentage = (negative_count / total) * 100,
    neutral_percentage  = (neutral_count / total) * 100
  )

  invisible(result)
}


#' Determine Emotional Trajectory
#'
#' Internal function to describe how sentiment changes through the song
#' by comparing the mean of the first third to the mean of the last third.
#'
#' @param scores Numeric vector of sentiment scores
#'
#' @return Character string describing trajectory
#' @keywords internal
#' @noRd
determine_trajectory <- function(scores) {

  n <- length(scores)
  if (n < 3) return("Insufficient data")

  first_third <- mean(scores[1:floor(n/3)], na.rm = TRUE)
  last_third  <- mean(scores[(n - floor(n/3)):n], na.rm = TRUE)
  diff        <- last_third - first_third

  if (diff > 0.5) {
    return("Gets more positive")
  } else if (diff < -0.5) {
    return("Gets more negative")
  } else {
    return("Maintains consistent tone")
  }
}