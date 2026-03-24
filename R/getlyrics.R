#' Get Lyrics from Genius (Direct API + Simple Scraping)
#'
#' Retrieves song lyrics by directly calling the Genius API and scraping
#' lyrics from the Genius website using rvest's html_text2().
#'
#' @param artist Character string of artist name
#' @param song Character string of song title
#' @param access_token Genius API token. If NULL, uses GENIUS_API_TOKEN env var
#'
#' @return A list of class "lyrics_lab" containing:
#'   \itemize{
#'     \item lyrics - Character vector of lyrics (one element per line)
#'     \item metadata - List with song info
#'     \item structure - Data frame with detected sections
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Set your token first
#' Sys.setenv(GENIUS_API_TOKEN = "your_token_here")
#' 
#' # Get lyrics
#' lyrics <- get_lyrics(artist = "Taylor Swift", song = "Anti-Hero")
#' }
#'
#' @importFrom httr GET add_headers content status_code
#' @importFrom jsonlite fromJSON
#' @importFrom rvest read_html html_elements html_text2
#' @importFrom stringr str_trim str_split
get_lyrics <- function(artist, song, access_token = NULL) {
  
  # Validate inputs
  if (missing(artist) || missing(song)) {
    stop("Both 'artist' and 'song' are required")
  }
  
  # Get access token
  if (is.null(access_token)) {
    access_token <- Sys.getenv("GENIUS_API_TOKEN")
    if (access_token == "") {
      stop(paste(
        "Genius API token not found.",
        "Set with: Sys.setenv(GENIUS_API_TOKEN = 'your_token')",
        "Get token at: https://genius.com/api-clients"
      ))
    }
  }
  
  message(sprintf("Searching for '%s' by %s...", song, artist))
  
  # Step 1: Search for the song using Genius API
  search_results <- genius_search(artist, song, access_token)
  
  if (is.null(search_results) || length(search_results) == 0) {
    stop(sprintf("No results found for '%s' by %s", song, artist))
  }
  
  # Get the first (most relevant) result
  song_info <- search_results[[1]]
  song_url <- song_info$url
  song_id <- song_info$id
  song_title <- song_info$title
  
  message(sprintf("Found: '%s' (ID: %s)", song_title, song_id))
  message(sprintf("URL: %s", song_url))
  
  # Step 2: Scrape lyrics from Genius website
  message("Fetching lyrics from Genius.com...")
  lyrics_text <- scrape_genius_lyrics(song_url)
  
  if (is.null(lyrics_text) || nchar(lyrics_text) == 0) {
    stop("Could not retrieve lyrics. The song may be instrumental or unavailable.")
  }
  
  # Step 3: Process lyrics into lines
  lyrics_lines <- process_lyrics(lyrics_text)
  
  # Step 4: Detect song structure
  structure <- detect_song_structure_simple(lyrics_lines)
  
  # Step 5: Create metadata
  metadata <- list(
    song_id = song_id,
    title = song_title,
    artist = song_info$artist_name,
    album = song_info$album_name,
    url = song_url,
    release_date = song_info$release_date
  )
  
  # Create result object
  # Use cleaned lyrics from structure (section markers removed)
  result <- list(
    lyrics = structure$lyric,  # Fixed: use cleaned lyrics
    metadata = metadata,
    structure = structure
  )
  
  class(result) <- c("lyrics_lab", "list")
  
  message(sprintf("Successfully retrieved %d lines of lyrics!", nrow(structure)))
  
  return(result)
}


#' Search Genius API
#'
#' Directly calls the Genius search API endpoint.
#'
#' @param artist Artist name
#' @param song Song title
#' @param access_token Genius API token
#'
#' @return List of search results
#' @keywords internal
#' @noRd
#'
#' @importFrom httr GET add_headers content status_code
#' @importFrom jsonlite fromJSON
genius_search <- function(artist, song, access_token) {
  
  # Build search query
  query <- paste(artist, song)
  
  # Genius API search endpoint
  url <- "https://api.genius.com/search"
  
  # Make API request
  response <- tryCatch({
    httr::GET(
      url,
      query = list(q = query),
      httr::add_headers(Authorization = paste("Bearer", access_token))
    )
  }, error = function(e) {
    stop(sprintf("API request failed: %s", e$message))
  })
  
  # Check status
  if (httr::status_code(response) != 200) {
    stop(sprintf("API returned status %d. Check your token.", 
                 httr::status_code(response)))
  }
  
  # Parse JSON response
  content <- httr::content(response, as = "text", encoding = "UTF-8")
  data <- jsonlite::fromJSON(content)
  
  if (is.null(data$response$hits) || length(data$response$hits) == 0) {
    return(NULL)
  }
  
  # Extract song information
  hits <- data$response$hits
  results <- list()
  
  for (i in 1:min(5, nrow(hits))) {  # Get top 5 results
    result <- hits$result[i, ]
    
    results[[i]] <- list(
      id = result$id,
      title = result$title,
      artist_name = result$primary_artist$name,
      album_name = if (!is.null(result$album)) result$album$name else "Unknown",
      url = result$url,
      release_date = result$release_date_for_display
    )
  }
  
  return(results)
}


#' Scrape Lyrics from Genius Website (Clean Version)
#'
#' Scrapes lyrics using rvest's html_text2() - much simpler!
#'
#' @param url Genius song URL
#'
#' @return Character string of lyrics text
#' @keywords internal
#' @noRd
#'
#' @importFrom rvest read_html html_elements html_text2

scrape_genius_lyrics <- function(url) {
  tryCatch({
    # Step 1: Read the HTML page
    page <- rvest::read_html(url)
    
    # Step 2: Select all lyrics container divs
    nodes <- rvest::html_elements(page, "div[class^='Lyrics__Container']")
    
    # Step 3: Extract text from nodes
    lyrics <- rvest::html_text2(nodes)
    
    # Step 4: Collapse into a single string
    lyrics <- paste(lyrics, collapse = "\n")
    
    if (nchar(lyrics) == 0) {
      stop("No lyrics found on page")
    }
    
    return(lyrics)
    
  }, error = function(e) {
    stop(sprintf("Failed to scrape lyrics: %s", e$message))
  })
}

#' Process Raw Lyrics Text
#'
#' Cleans and splits lyrics into lines.
#'
#' @param lyrics_text Raw lyrics text
#'
#' @return Character vector of lyrics lines
#' @keywords internal
#' @noRd
#'
#' @importFrom stringr str_trim str_split
process_lyrics <- function(lyrics_text) {
  
  # Split by newlines
  lines <- unlist(strsplit(lyrics_text, "\n"))
  
  # Trim whitespace
  lines <- stringr::str_trim(lines)
  
  # Remove empty lines
  lines <- lines[lines != ""]
  
  return(lines)
}


#' Detect Song Structure (Simple Version)
#'
#' Identifies verses, choruses, bridges from section markers in lyrics.
#'
#' @param lyrics_lines Character vector of lyrics lines
#'
#' @return Data frame with line numbers, lyrics, and sections
#' @keywords internal
#' @noRd
detect_song_structure_simple <- function(lyrics_lines) {
  
  sections <- character(length(lyrics_lines))
  current_section <- "verse"
  
  for (i in seq_along(lyrics_lines)) {
    line <- lyrics_lines[i]
    line_lower <- tolower(line)
    
    # Check if this line is a section marker
    if (grepl("^\\[.*\\]$", line)) {
      # This is a section marker
      if (grepl("chorus", line_lower)) {
        current_section <- "chorus"
      } else if (grepl("verse", line_lower)) {
        current_section <- "verse"
      } else if (grepl("bridge", line_lower)) {
        current_section <- "bridge"
      } else if (grepl("intro", line_lower)) {
        current_section <- "intro"
      } else if (grepl("outro", line_lower)) {
        current_section <- "outro"
      } else if (grepl("pre-chorus", line_lower) || grepl("pre chorus", line_lower)) {
        current_section <- "pre-chorus"
      } else if (grepl("hook", line_lower)) {
        current_section <- "hook"
      }
      sections[i] <- current_section
    } else {
      # Regular lyric line
      sections[i] <- current_section
    }
  }
  
  # Create structure data frame
  structure <- data.frame(
    line_number = seq_along(lyrics_lines),
    lyric = lyrics_lines,
    section = sections,
    stringsAsFactors = FALSE
  )
  
  # Remove section marker lines from the structure
  # (lines that are just [Verse 1], etc.)
  structure <- structure[!grepl("^\\[.*\\]$", structure$lyric), ]
  
  # Renumber lines
  structure$line_number <- seq_len(nrow(structure))
  
  return(structure)
}


#' Get Multiple Lyrics
#'
#' Batch retrieve lyrics for multiple songs.
#'
#' @param artist Character string or vector of artist names
#' @param songs Character vector of song titles
#' @param delay Numeric; seconds to wait between requests. Default 2
#' @param access_token Genius API token (optional)
#'
#' @return A list of lyrics_lab objects
#'
#' @export
#'
#' @examples
#' \dontrun{
#' songs <- c("Anti-Hero", "Karma", "Lavender Haze")
#' lyrics_list <- get_multiple_lyrics("Taylor Swift", songs)
#' }
get_multiple_lyrics <- function(artist, songs, delay = 2, access_token = NULL) {
  
  # Validate inputs
  if (length(artist) == 1) {
    artist <- rep(artist, length(songs))
  } else if (length(artist) != length(songs)) {
    stop("'artist' must be either length 1 or same length as 'songs'")
  }
  
  message(sprintf("Fetching %d songs...", length(songs)))
  
  lyrics_list <- list()
  success_count <- 0
  
  for (i in seq_along(songs)) {
    message(sprintf("\n[%d/%d] ", i, length(songs)))
    
    result <- tryCatch({
      get_lyrics(artist = artist[i], song = songs[i], access_token = access_token)
    }, error = function(e) {
      message(sprintf("✗ Failed: %s", e$message))
      return(NULL)
    })
    
    if (!is.null(result)) {
      lyrics_list[[songs[i]]] <- result
      success_count <- success_count + 1
    }
    
    # Rate limiting (be nice to Genius servers)
    if (i < length(songs) && delay > 0) {
      Sys.sleep(delay)
    }
  }
  
  message(sprintf("\n✓ Successfully retrieved %d/%d songs", success_count, length(songs)))
  
  return(lyrics_list)
}


#' Validate Lyrics Object
#'
#' Checks if object is a valid lyrics_lab object.
#'
#' @param obj Object to validate
#'
#' @return TRUE if valid, stops with error otherwise
#' @keywords internal
#' @noRd
validate_lyrics <- function(obj) {
  
  if (!inherits(obj, "lyrics_lab")) {
    stop("Input must be a lyrics object from get_lyrics()")
  }
  
  required_elements <- c("lyrics", "metadata", "structure")
  missing_elements <- setdiff(required_elements, names(obj))
  
  if (length(missing_elements) > 0) {
    stop(sprintf("Invalid lyrics object. Missing: %s", 
                 paste(missing_elements, collapse = ", ")))
  }
  
  if (length(obj$lyrics) == 0) {
    stop("Lyrics object is empty")
  }
  
  return(TRUE)
}

#' View Full Lyrics
#'
#' Prints all lines of a lyrics_lab object.
#'
#' @param x A lyrics_lab object
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
#' view_lyrics(lyrics)
#' }
view_lyrics <- function(x) {
  title  <- x$metadata$title
  artist <- x$metadata$artist
 
  cat(sprintf("%s - %s\n\n", title, artist))
  cat(paste(x$lyrics, collapse = "\n"))
  cat("\n")
 
  invisible(x)
}

#' Preview Lyrics
#'
#' Shows metadata and the first few lines of a lyrics_lab object.
#'
#' @param x A lyrics_lab object
#' @param n Number of lines to show. Default 5
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lyrics <- get_lyrics("Taylor Swift", "Anti-Hero")
#' preview_lyrics(lyrics)
#' preview_lyrics(lyrics, n = 10)
#' }
preview_lyrics <- function(x, n = 5) {
  title    <- x$metadata$title
  artist   <- x$metadata$artist
  album    <- x$metadata$album
  url      <- x$metadata$url
  n_lines  <- length(x$lyrics)
  sections <- unique(x$structure$section)
 
  cat(sprintf("Song:     %s\n", title))
  cat(sprintf("Artist:   %s\n", artist))
  if (!is.null(album) && album != "Unknown") cat(sprintf("Album:    %s\n", album))
  cat(sprintf("Lines:    %d\n", n_lines))
  cat(sprintf("URL:      %s\n", url))
  cat(sprintf("Sections: %s\n\n", paste(sections, collapse = ", ")))
  cat(paste(head(x$lyrics, n), collapse = "\n"))
  if (n_lines > n) cat("\n...\n")
 
  invisible(x)
}