#' Connect to Spotify API
#'
#' Authenticates with Spotify and gets user authorization.
#' You'll need to create a Spotify App first at https://developer.spotify.com/dashboard
#'
#' @param client_id Your Spotify Client ID
#' @param client_secret Your Spotify Client Secret
#'
#' @return Access token (saved to environment)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' spotify_auth(
#'   client_id = "your_client_id",
#'   client_secret = "your_client_secret"
#' )
#' }
#'
#' @importFrom httr POST content status_code
spotify_auth <- function(client_id = NULL, client_secret = NULL) {

  # Prevent crash during R CMD check
  if (!interactive()) {
    stop("spotify_auth() must be run in an interactive R session.")
  }

  # Check httpuv
  if (!requireNamespace("httpuv", quietly = TRUE)) {
    stop("httpuv package required. Install with install.packages('httpuv')")
  }

  # Get credentials
  if (is.null(client_id)) {
    client_id <- Sys.getenv("SPOTIFY_CLIENT_ID")
  }
  if (is.null(client_secret)) {
    client_secret <- Sys.getenv("SPOTIFY_CLIENT_SECRET")
  }

  client_id <- trimws(client_id)
  client_secret <- trimws(client_secret)

  if (client_id == "" || client_secret == "") {
    stop("Spotify credentials not found. Set with Sys.setenv().")
  }

  redirect_uri <- "http://127.0.0.1:1410/"
  port <- 1410

  scopes <- c(
    "user-read-recently-played",
    "user-top-read",
    "user-library-read",
    "playlist-read-private"
  )

  scope_string <- paste(scopes, collapse = " ")

  state <- paste(sample(c(letters, LETTERS, 0:9), 20, replace = TRUE), collapse = "")

  auth_url <- paste0(
    "https://accounts.spotify.com/authorize",
    "?client_id=", client_id,
    "&response_type=code",
    "&redirect_uri=", utils::URLencode(redirect_uri, reserved = TRUE),
    "&scope=", utils::URLencode(scope_string, reserved = TRUE),
    "&state=", state
  )

  message("\nOpening browser for Spotify authentication...")

  auth_code <- NULL

  app <- list(
    call = function(req) {
      query <- req$QUERY_STRING

      if (grepl("code=", query)) {
        code <- sub(".*code=([^&]+).*", "\\1", query)
        auth_code <<- code

        list(
          status = 200L,
          headers = list('Content-Type' = 'text/html'),
          body = "<h1>Authentication successful! You can close this window.</h1>"
        )
      } else {
        list(
          status = 400L,
          headers = list('Content-Type' = 'text/html'),
          body = "<h1>Authentication failed</h1>"
        )
      }
    }
  )

  # Start server
  server <- httpuv::startServer("127.0.0.1", port, app)
  on.exit(httpuv::stopServer(server), add = TRUE)

  # Open browser safely
  if (interactive()) {
    utils::browseURL(auth_url)
  } else {
    message("Open this URL manually: ", auth_url)
  }

  message("Waiting for authorization...")

  timeout <- 60
  elapsed <- 0

  while (is.null(auth_code) && elapsed < timeout) {
    httpuv::service(timeout = 100)
    Sys.sleep(0.1)
    elapsed <- elapsed + 0.1
  }

  if (is.null(auth_code)) {
    stop("Authentication timeout.")
  }

  message("Exchanging code for token...")

  token_response <- httr::POST(
    "https://accounts.spotify.com/api/token",
    encode = "form",
    body = list(
      grant_type = "authorization_code",
      code = auth_code,
      redirect_uri = redirect_uri,
      client_id = client_id,
      client_secret = client_secret
    )
  )

  if (httr::status_code(token_response) != 200) {
    stop("Token exchange failed.")
  }

  token_data <- httr::content(token_response)

  token <- list(
    credentials = list(
      access_token = token_data$access_token,
      refresh_token = token_data$refresh_token,
      expires_in = token_data$expires_in,
      expires_at = as.numeric(Sys.time()) + token_data$expires_in
    )
  )

  class(token) <- "Token2.0"

  assign("spotify_token", token, envir = .GlobalEnv)

  message("Authentication successful!")

  invisible(token)
}

#' Get Tracks from a Spotify Playlist
#'
#' Retrieves all tracks from a Spotify playlist by URL or ID.
#'
#' @param playlist_url Spotify playlist URL or ID
#' @param token Spotify token (uses saved token if NULL)
#'
#' @return Data frame with track information
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Using playlist URL
#' playlist <- get_playlist_tracks(
#'   "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
#' )
#' 
#' # Using just the playlist ID
#' playlist <- get_playlist_tracks("37i9dQZF1DXcBWIGoYBM5M")
#' 
#' # View tracks
#' print(playlist[, c("track_name", "artist_name")])
#' }
#'
#' @importFrom httr GET add_headers content status_code
#' @importFrom jsonlite fromJSON
get_playlist_tracks <- function(playlist_url, token = NULL) {
  
  if (is.null(token)) {
    if (!exists("spotify_token", envir = .GlobalEnv)) {
      stop("Not authenticated. Run spotify_auth() first.")
    }
    token <- get("spotify_token", envir = .GlobalEnv)
  }
  
  if (grepl("spotify.com/playlist/", playlist_url)) {
    playlist_id <- sub(".*playlist/([^?]+).*", "\\1", playlist_url)
  } else {
    playlist_id <- playlist_url
  }
  
  message(sprintf("Fetching playlist: %s", playlist_id))
  
  playlist_response <- httr::GET(
    sprintf("https://api.spotify.com/v1/playlists/%s", playlist_id),
    httr::add_headers(Authorization = paste("Bearer", token$credentials$access_token))
  )
  
  if (httr::status_code(playlist_response) != 200) {
    stop(sprintf("Failed to get playlist. Status: %d", httr::status_code(playlist_response)))
  }
  
  playlist_data <- jsonlite::fromJSON(
    httr::content(playlist_response, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )
  
  message(sprintf("Playlist: '%s' by %s",
                  playlist_data$name,
                  playlist_data$owner$display_name))
  message(sprintf("Total tracks: %d", playlist_data$items$total))
  
  all_tracks <- list()
  
  # Use the already-returned first page and its next URL for pagination
  page <- playlist_data$items
  
  repeat {
    items <- page$items
    offset <- page$offset
    total  <- page$total
    
    message(sprintf("  Fetching tracks %d-%d...", offset + 1, min(offset + length(items), total)))
    
    for (item in items) {
    track <- item$item  # was item$track
  
  if (is.null(track) || is.null(track$id)) next
  
  artists <- track$artists
  if (!is.null(artists) && length(artists) > 0) {
    artist_names <- paste(sapply(artists, function(a) {
      if (is.null(a$name)) NA_character_ else a$name
    }), collapse = ", ")
    artist_id <- if (is.null(artists[[1]]$id)) NA_character_ else artists[[1]]$id
  } else {
    artist_names <- NA_character_
    artist_id    <- NA_character_
  }
  
  track_info <- list(
    track_name  = if (is.null(track$name))        NA_character_ else track$name,
    track_id    = if (is.null(track$id))           NA_character_ else track$id,
    artist_name = artist_names,
    artist_id   = artist_id,
    album_name  = if (is.null(track$album$name))   NA_character_ else track$album$name,
    album_id    = if (is.null(track$album$id))     NA_character_ else track$album$id,
    duration_ms = if (is.null(track$duration_ms))  NA_integer_   else track$duration_ms,
    popularity  = if (is.null(track$popularity))   NA_integer_   else track$popularity,
    added_at    = if (is.null(item$added_at))      NA_character_ else item$added_at,
    added_by    = if (is.null(item$added_by$id))   NA_character_ else item$added_by$id
  )
  
  all_tracks[[length(all_tracks) + 1]] <- track_info
}
    
    # Follow the next URL if there is one
    next_url <- page$`next`
    if (is.null(next_url)) break
    
    Sys.sleep(0.3)
    
    next_response <- httr::GET(
      next_url,
      httr::add_headers(Authorization = paste("Bearer", token$credentials$access_token))
    )
    
    if (httr::status_code(next_response) != 200) {
      warning(sprintf("Error fetching next page: status %d", httr::status_code(next_response)))
      break
    }
    
    page <- jsonlite::fromJSON(
      httr::content(next_response, as = "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )
  }
  
  if (length(all_tracks) == 0) {
    message("No tracks found in playlist")
    return(data.frame())
  }
  
  df <- do.call(rbind, lapply(all_tracks, as.data.frame, stringsAsFactors = FALSE))
  df$added_at      <- as.POSIXct(df$added_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  df$playlist_name <- playlist_data$name
  df$playlist_id   <- playlist_id
  
  message(sprintf("\n✓ Retrieved %d tracks from '%s'", nrow(df), playlist_data$name))
  
  return(df)
}

#' Get Recently Played Tracks
#'
#' Retrieves your 50 most recently played tracks from Spotify.
#' This is the maximum the Spotify API allows in a single request.
#'
#' @param token Spotify token (uses saved token if NULL)
#'
#' @return Data frame with track information and play times containing:
#'   \itemize{
#'     \item played_at - POSIXct timestamp of when the track was played
#'     \item track_name - Track title
#'     \item track_id - Spotify track ID
#'     \item artist_name - Artist name(s)
#'     \item artist_id - Primary artist ID
#'     \item album_name - Album title
#'     \item album_id - Spotify album ID
#'     \item duration_ms - Track duration in milliseconds
#'     \item popularity - Spotify popularity score (0-100)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' history <- get_recently_played()
#'
#' # Most played artists
#' sort(table(history$artist_name), decreasing = TRUE)
#' }
#'
#' @importFrom httr GET add_headers content status_code
#' @importFrom jsonlite fromJSON
get_recently_played <- function(token = NULL) {

  if (is.null(token)) {
    if (!exists("spotify_token", envir = .GlobalEnv)) {
      stop("Not authenticated. Run spotify_auth() first.")
    }
    token <- get("spotify_token", envir = .GlobalEnv)
  }

  message("Fetching recently played tracks...")

  response <- httr::GET(
    "https://api.spotify.com/v1/me/player/recently-played",
    query = list(limit = 50),
    httr::add_headers(Authorization = paste("Bearer", token$credentials$access_token))
  )

  if (httr::status_code(response) != 200) {
    stop(sprintf("API error: %d", httr::status_code(response)))
  }

  data <- jsonlite::fromJSON(
    httr::content(response, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )

  items <- data$items

  if (is.null(items) || length(items) == 0) {
    message("No recently played tracks found.")
    return(data.frame())
  }

  all_tracks <- list()

  for (item in items) {
    track <- item$track

    if (is.null(track) || is.null(track$id)) next

    artists <- track$artists
    if (!is.null(artists) && length(artists) > 0) {
      artist_names <- paste(sapply(artists, function(a) {
        if (is.null(a$name)) NA_character_ else a$name
      }), collapse = ", ")
      artist_id <- if (is.null(artists[[1]]$id)) NA_character_ else artists[[1]]$id
    } else {
      artist_names <- NA_character_
      artist_id    <- NA_character_
    }

    track_info <- list(
      played_at   = if (is.null(item$played_at))     NA_character_ else item$played_at,
      track_name  = if (is.null(track$name))          NA_character_ else track$name,
      track_id    = if (is.null(track$id))            NA_character_ else track$id,
      artist_name = artist_names,
      artist_id   = artist_id,
      album_name  = if (is.null(track$album$name))    NA_character_ else track$album$name,
      album_id    = if (is.null(track$album$id))      NA_character_ else track$album$id,
      duration_ms = if (is.null(track$duration_ms))   NA_integer_   else track$duration_ms,
      popularity  = if (is.null(track$popularity))    NA_integer_   else track$popularity
    )

    all_tracks[[length(all_tracks) + 1]] <- track_info
  }

  if (length(all_tracks) == 0) {
    message("No tracks found.")
    return(data.frame())
  }

  df           <- do.call(rbind, lapply(all_tracks, as.data.frame, stringsAsFactors = FALSE))
  df$played_at <- as.POSIXct(df$played_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  df           <- df[order(df$played_at, decreasing = TRUE), ]

  time_span <- difftime(max(df$played_at), min(df$played_at), units = "hours")

  cat(sprintf("\n=== Recently Played ===\n"))
  cat(sprintf("  Tracks retrieved:  %d\n", nrow(df)))
  cat(sprintf("  From:              %s\n", format(min(df$played_at), "%Y-%m-%d %H:%M")))
  cat(sprintf("  To:                %s\n", format(max(df$played_at), "%Y-%m-%d %H:%M")))
  cat(sprintf("  Time span:         %.1f hours\n\n", as.numeric(time_span)))

  return(df)
}

#' Get Top Tracks
#'
#' Retrieves your top tracks from Spotify.
#'
#' @param time_range Time range: "short_term" (4 weeks), "medium_term" (6 months), 
#'   or "long_term" (all time). Default "medium_term"
#' @param limit Number of tracks to retrieve (max 50). Default 20
#' @param token Spotify token (uses saved token if NULL)
#'
#' @return Data frame with track information
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Top tracks all time
#' top_tracks <- get_top_tracks(time_range = "long_term", limit = 50)
#' print(top_tracks[, c("rank", "track_name", "artist_name")])
#' }
#'
#' @importFrom httr GET add_headers content
#' @importFrom jsonlite fromJSON
get_top_tracks <- function(time_range = "medium_term", limit = 20, token = NULL) {
  
  # Get token
  if (is.null(token)) {
    if (!exists("spotify_token", envir = .GlobalEnv)) {
      stop("Not authenticated. Run spotify_auth() first.")
    }
    token <- get("spotify_token", envir = .GlobalEnv)
  }
  
  # Validate time_range
  if (!time_range %in% c("short_term", "medium_term", "long_term")) {
    stop("time_range must be 'short_term', 'medium_term', or 'long_term'")
  }
  
  message(sprintf("Fetching top %d tracks (%s)...", limit, time_range))
  
  # Make request
  response <- httr::GET(
    "https://api.spotify.com/v1/me/top/tracks",
    query = list(time_range = time_range, limit = limit),
    httr::add_headers(Authorization = paste("Bearer", token$credentials$access_token))
  )
  
  if (httr::status_code(response) != 200) {
    stop(sprintf("API error: %d", httr::status_code(response)))
  }
  
  # Parse response
  data <- jsonlite::fromJSON(httr::content(response, as = "text"))
  
  if (is.null(data$items) || length(data$items) == 0) {
    message("No top tracks found")
    return(data.frame())
  }
  
  # Extract track info
  tracks_list <- list()
  for (i in 1:nrow(data$items)) {
    track <- data$items[i, ]
    
    tracks_list[[i]] <- list(
      rank = i,
      track_name = track$name,
      track_id = track$id,
      artist_name = paste(sapply(track$artists, function(a) a$name), collapse = ", "),
      artist_id = track$artists[[1]]$id[1],
      album_name = track$album$name,
      popularity = track$popularity,
      duration_ms = track$duration_ms
    )
  }
  
  df <- do.call(rbind, lapply(tracks_list, as.data.frame))
  
  message(sprintf("✓ Retrieved %d tracks", nrow(df)))
  
  return(df)
}