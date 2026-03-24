#' Calculate Lyrical Complexity
#'
#' Computes comprehensive complexity metrics including vocabulary richness,
#' average word length, reading level, and syllable complexity.
#' Prints a clean summary to the console and returns results invisibly.
#'
#' @param lyrics_obj Lyrics object from \code{get_lyrics()}
#'
#' @return Invisibly returns a list containing:
#'   \itemize{
#'     \item vocabulary_size - Number of unique words
#'     \item total_words - Total word count
#'     \item type_token_ratio - Vocabulary richness (0-1)
#'     \item avg_word_length - Mean characters per word
#'     \item reading_level - Estimated grade level (Flesch-Kincaid)
#'     \item syllables_per_word - Average syllables per word
#'     \item interpretation - Text description of complexity
#'     \item complexity_score - Overall score (0-100)
#'     \item song - Track title
#'     \item artist - Artist name
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Kendrick Lamar", "HUMBLE.")
#' complexity_score(lyrics)
#'
#' # Store result invisibly if needed
#' result <- complexity_score(lyrics)
#' }
complexity_score <- function(lyrics_obj) {
  
  validate_lyrics(lyrics_obj)
  
  message("Calculating complexity metrics...")
  
  full_text <- paste(lyrics_obj$lyrics, collapse = " ")
  
  words <- tolower(full_text)
  words <- unlist(strsplit(words, "\\s+"))
  words <- gsub("[^a-z']", "", words)
  words <- words[words != ""]
  
  total_words     <- length(words)
  unique_words    <- length(unique(words))
  ttr             <- unique_words / total_words
  avg_word_length <- mean(nchar(words), na.rm = TRUE)
  
  syllables          <- estimate_syllables(words)
  syllables_per_word <- mean(syllables, na.rm = TRUE)
  
  sentences <- length(lyrics_obj$lyrics)
  if (sentences > 0) {
    reading_level <- 0.39 * (total_words / sentences) +
                     11.8 * syllables_per_word - 15.59
    reading_level <- max(1, round(reading_level, 1))
  } else {
    reading_level <- NA
  }
  
  complexity <- (
    (ttr * 30) +
    (min(reading_level / 16, 1) * 30) +
    (min(avg_word_length / 10, 1) * 20) +
    (min(syllables_per_word / 3, 1) * 20)
  )
  
  interpretation <- if (reading_level <= 5) {
    "Elementary level - very simple vocabulary"
  } else if (reading_level <= 8) {
    "Middle school level - simple vocabulary"
  } else if (reading_level <= 10) {
    "High school level - moderate complexity"
  } else if (reading_level <= 13) {
    "College level - advanced vocabulary"
  } else {
    "Graduate level - highly complex"
  }
  
  message("✓ Complexity analysis complete!")
  
  cat(sprintf("\n=== Complexity: %s by %s ===\n",
              lyrics_obj$metadata$title, lyrics_obj$metadata$artist))
  cat(sprintf("  Vocabulary size:     %d unique / %d total words\n", unique_words, total_words))
  cat(sprintf("  Vocabulary richness: %.3f\n", ttr))
  cat(sprintf("  Avg word length:     %.2f characters\n", avg_word_length))
  cat(sprintf("  Syllables per word:  %.2f\n", syllables_per_word))
  cat(sprintf("  Reading level:       %.1f (grade)\n", reading_level))
  cat(sprintf("  Complexity score:    %.1f / 100\n", complexity))
  cat(sprintf("  Interpretation:      %s\n\n", interpretation))
  
  result <- list(
    vocabulary_size    = unique_words,
    total_words        = total_words,
    type_token_ratio   = round(ttr, 3),
    avg_word_length    = round(avg_word_length, 2),
    reading_level      = reading_level,
    syllables_per_word = round(syllables_per_word, 2),
    interpretation     = interpretation,
    complexity_score   = round(complexity, 1),
    song               = lyrics_obj$metadata$title,
    artist             = lyrics_obj$metadata$artist
  )
  
  invisible(result)
}

#' Estimate Syllables in Words
#'
#' Rough syllable count approximation for English words.
#'
#' @param words Character vector of words
#'
#' @return Numeric vector of syllable counts
#' @keywords internal
#' @noRd
estimate_syllables <- function(words) {
  
  syllables <- sapply(words, function(word) {
    # Count vowel groups
    vowels <- gregexpr("[aeiouy]+", word, ignore.case = TRUE)[[1]]
    count <- length(vowels[vowels > 0])
    
    # Adjust for silent e
    if (grepl("e$", word, ignore.case = TRUE) && count > 1) {
      count <- count - 1
    }
    
    # Adjust for -le endings
    if (grepl("le$", word, ignore.case = TRUE) && count > 1) {
      count <- count + 0.5
    }
    
    # Minimum 1 syllable
    return(max(1, round(count)))
  })
  
  return(unname(syllables))
}
