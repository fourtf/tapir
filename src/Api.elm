module Api exposing (apiGet, authorizationUrl, getUserByLogin)

import Http exposing (header, request)
import Url.Builder exposing (crossOrigin, string)


baseUrl : String
baseUrl =
    "https://api.twitch.tv/helix"


clientId : String
clientId =
    "o114479h5askdxyakpic86pvutfd4m"


auth : String -> Http.Header
auth accessToken =
    header "Authorization" <| "Bearer " ++ accessToken


scopes : List String
scopes =
    [ "user_subscriptions"
    , "user_blocks_edit"
    , -- deprecated, replaced with "user:manage:blocked_users"
      "user_blocks_read"
    , -- deprecated, replaced with "user:read:blocked_users"
      "user_follows_edit"
    , -- deprecated, soon to be removed later since we now use "user:edit:follows"
      "channel_editor"
    , -- for /raid
      "channel:moderate"
    , "channel:read:redemptions"
    , "chat:edit"
    , "chat:read"
    , "whispers:read"
    , "whispers:edit"
    , "channel_commercial"
    , -- for /commercial
      "channel:edit:commercial"
    , -- in case twitch upgrades things in the future (and this scope is required)
      "user:edit:follows"
    , -- for (un)following
      "clips:edit"
    , -- for clip creation
      "channel:manage:broadcast"
    , -- for creating stream markers with /marker command, and for the /settitle and /setgame commands
      "user:read:blocked_users"
    , -- for getting list of blocked users
      "user:manage:blocked_users" -- for blocking/unblocking other users
    ]


redirectUri : String
redirectUri =
    "http://localhost:4850/auth"


authorizationUrl : String
authorizationUrl =
    crossOrigin "https://id.twitch.tv"
        [ "oauth2", "authorize" ]
        [ string "response_type" "token"
        , string "client_id" clientId
        , string "redirect_uri" redirectUri
        , string "scope" <| String.join " " <| scopes
        ]


apiGet : String -> Http.Expect msg -> String -> Cmd msg
apiGet url expect accessToken =
    request
        { method = "GET"
        , headers = [ auth accessToken, header "Client-Id" clientId ]
        , url = url
        , body = Http.emptyBody
        , expect = expect
        , timeout = Just 30000
        , tracker = Nothing
        }


getUserByLogin : String -> String
getUserByLogin name =
    crossOrigin baseUrl [ "users" ] [ string "login" name ]
