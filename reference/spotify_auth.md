# Connect to Spotify API

Authenticates with Spotify and gets user authorization. You'll need to
create a Spotify App first at https://developer.spotify.com/dashboard

## Usage

``` r
spotify_auth(client_id = NULL, client_secret = NULL)
```

## Arguments

- client_id:

  Your Spotify Client ID

- client_secret:

  Your Spotify Client Secret

- redirect_uri:

  Redirect URI (default: http://localhost:8888/callback)

## Value

Access token (saved to environment)

## Examples

``` r
if (FALSE) { # \dontrun{
# First time setup
spotify_auth(
  client_id = "your_client_id",
  client_secret = "your_client_secret"
)

# Token is saved, now you can use other functions
history <- get_listening_history()
} # }
```
