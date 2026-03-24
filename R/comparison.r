#' Detect Themes in Lyrics
#'
#' Identifies the main themes present in lyrics using keyword matching
#' across 23 theme categories. Prints a clean summary to the console
#' and returns results invisibly.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item themes - Data frame of all themes with scores and percentages
#'     \item dominant_theme - Name of the top scoring theme
#'     \item dominant_score - Keyword match count for dominant theme
#'     \item summary - One-line text summary
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Adele", "Someone Like You")
#' theme_detection(lyrics)
#'
#' # Store result invisibly if needed
#' result <- theme_detection(lyrics)
#' }
theme_detection <- function(lyrics_obj) {
  
  validate_lyrics(lyrics_obj)
  
  message("Detecting themes...")
  
  full_text <- tolower(paste(lyrics_obj$lyrics, collapse = " "))
  
  themes_dict <- list(
    "Love/Romance"       = c("love", "heart", "kiss", "together", "forever", "baby",
                             "darling", "honey", "romance", "affection"),
    "Heartbreak"         = c("goodbye", "leaving", "left", "broken", "tears", "cry",
                             "alone", "miss", "lost", "pain", "hurt"),
    "Party/Fun"          = c("party", "dance", "night", "club", "drink", "celebration",
                             "fun", "crazy", "wild", "tonight"),
    "Self-Reflection"    = c("myself", "thinking", "wondering", "realize", "understand",
                             "remember", "memory", "mind", "thought"),
    "Anger/Conflict"     = c("anger", "hate", "fight", "war", "enemy", "revenge",
                             "mad", "furious", "argue"),
    "Hope/Dreams"        = c("hope", "dream", "wish", "future", "believe", "faith",
                             "tomorrow", "someday", "destiny"),
    "Nostalgia"          = c("yesterday", "remember", "used to", "back then", "memories",
                             "past", "old", "recall"),
    "Celebration"        = c("celebrate", "victory", "win", "success", "champion",
                             "achievement", "triumph", "glory"),
    "Empowerment"        = c("strong", "power", "rise", "independent", "free",
                             "unstoppable", "confident", "brave", "fearless"),
    "Sadness/Depression" = c("sad", "empty", "lonely", "dark", "down",
                             "depressed", "hopeless", "tired", "crying"),
    "Jealousy"           = c("jealous", "envy", "mine", "yours", "steal",
                             "possess", "watching", "control"),
    "Lust/Desire"        = c("touch", "body", "desire", "heat", "skin",
                             "burn", "crave", "want you", "need you"),
    "Rebellion"          = c("rebel", "rules", "break", "wild", "freedom",
                             "fight back", "no control"),
    "Wealth/Success"     = c("money", "rich", "gold", "cash", "luxury",
                             "fame", "boss", "grind", "hustle"),
    "Struggle/Survival"  = c("struggle", "pain", "fight", "survive", "hard",
                             "battle", "stress", "pressure"),
    "Friendship"         = c("friend", "together", "crew", "team", "brother",
                             "sister", "loyal"),
    "Freedom/Escape"     = c("free", "escape", "run away", "fly", "leave",
                             "road", "break away"),
    "Nature"             = c("sky", "ocean", "river", "rain", "sun",
                             "moon", "stars", "wind", "mountain"),
    "Spirituality"       = c("god", "heaven", "pray", "soul", "spirit",
                             "faith", "bless", "angel"),
    "Regret/Guilt"       = c("sorry", "regret", "mistake", "forgive",
                             "apologize", "guilt"),
    "Violence"           = c("gun", "blood", "kill", "die", "weapon", "shoot"),
    "Time/Change"        = c("time", "change", "grow", "older", "young",
                             "moment", "lifetime"),
    "Isolation"          = c("alone", "isolated", "empty", "nobody",
                             "silent", "apart", "distance")
  )
  
  theme_scores <- data.frame(
    theme = names(themes_dict),
    score = 0,
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(themes_dict)) {
    keywords <- themes_dict[[i]]
    count <- sum(sapply(keywords, function(kw) {
      if (grepl(" ", kw)) {
        lengths(regmatches(full_text, gregexpr(kw, full_text, fixed = TRUE)))
      } else {
        lengths(regmatches(full_text, gregexpr(paste0("\\b", kw, "\\w*\\b"), full_text)))
      }
    }))
    theme_scores$score[i] <- count
  }
  
  theme_scores   <- theme_scores[order(-theme_scores$score), ]
  total_keywords <- sum(theme_scores$score)
  theme_scores$percentage <- if (total_keywords > 0) {
    round((theme_scores$score / total_keywords) * 100, 1)
  } else {
    0
  }
  
  dominant_theme <- if (total_keywords > 0) {
    theme_scores$theme[1]
  } else {
    "No dominant theme detected"
  }
  
  message("✓ Theme detection complete!")
  
  cat(sprintf("\n=== Themes: %s by %s ===\n",
              lyrics_obj$metadata$title, lyrics_obj$metadata$artist))
  top5 <- head(theme_scores[theme_scores$score > 0, ], 5)
  for (i in seq_len(nrow(top5))) {
    cat(sprintf("  %-22s %d matches (%.1f%%)\n",
                top5$theme[i], top5$score[i], top5$percentage[i]))
  }
  cat(sprintf("\n  Dominant theme: %s\n\n", dominant_theme))
  
  result <- list(
    themes         = theme_scores,
    dominant_theme = dominant_theme,
    dominant_score = theme_scores$score[1],
    summary        = sprintf("Primary theme: %s (%d keyword matches)",
                             dominant_theme, theme_scores$score[1])
  )
  
  invisible(result)
}


#' Plot Lyrical Themes
#'
#' Creates a bar chart of the top theme keyword matches found in the lyrics.
#' Only themes with at least one match are shown, up to a maximum of 10.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#'
#' @return Invisibly returns a ggplot object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Adele", "Someone Like You")
#' plot_themes(lyrics)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_col coord_flip labs theme_minimal
#' theme element_text element_blank
plot_themes <- function(lyrics_obj) {
  
  result <- theme_detection(lyrics_obj)
  
  plot_data       <- head(result$themes[result$themes$score > 0, ], 10)
  plot_data$theme <- factor(plot_data$theme, levels = rev(plot_data$theme))
  
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = theme, y = score)) +
    ggplot2::geom_col(fill = "#ff6b6b", alpha = 0.8, width = 0.7) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title    = sprintf("Themes: \"%s\"", lyrics_obj$metadata$title),
      subtitle = sprintf("by %s | Dominant: %s",
                         lyrics_obj$metadata$artist, result$dominant_theme),
      x        = NULL,
      y        = "Keyword matches"
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title         = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle      = ggplot2::element_text(color = "gray40"),
      panel.grid.major.y = ggplot2::element_blank()
    )
  
  print(p)
  invisible(p)
}




#' Analyze Collection of Lyrics
#'
#' Helper function to aggregate metrics across multiple songs.
#'
#' @param lyrics_list List of lyrics objects
#' @param name Character string identifier
#'
#' @return List of aggregated metrics
#' @keywords internal
#' @noRd
analyze_artist_collection <- function(lyrics_list, name) {
  
  # Remove NULL entries
  lyrics_list <- lyrics_list[!sapply(lyrics_list, is.null)]
  
  if (length(lyrics_list) == 0) {
    stop("No valid lyrics found")
  }
  
  # Calculate metrics for each song
  sentiments <- sapply(lyrics_list, function(l) {
    tryCatch(sentiment_score(l)$score, error = function(e) NA)
  })
  
  complexities <- sapply(lyrics_list, function(l) {
    tryCatch(complexity_score(l)$complexity_score, error = function(e) NA)
  })
  
  reading_levels <- sapply(lyrics_list, function(l) {
    tryCatch(complexity_score(l)$reading_level, error = function(e) NA)
  })
  
  vocab_sizes <- sapply(lyrics_list, function(l) {
    tryCatch(complexity_score(l)$vocabulary_size, error = function(e) NA)
  })
  
  repetitions <- sapply(lyrics_list, function(l) {
    tryCatch(repetition_analysis(l)$repetition_percentage, error = function(e) NA)
  })
  
  profanities <- sapply(lyrics_list, function(l) {
    tryCatch(profanity_score(l)$profanity_score, error = function(e) NA)
  })
  
  # Aggregate
  result <- list(
    name = name,
    n_songs = length(lyrics_list),
    avg_sentiment = mean(sentiments, na.rm = TRUE),
    avg_complexity = mean(complexities, na.rm = TRUE),
    avg_reading_level = mean(reading_levels, na.rm = TRUE),
    avg_vocab_size = mean(vocab_sizes, na.rm = TRUE),
    avg_repetition = mean(repetitions, na.rm = TRUE),
    avg_profanity = mean(profanities, na.rm = TRUE)
  )
  
  return(result)
}