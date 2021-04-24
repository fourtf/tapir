module Api exposing
    ( AccessToken
    , UserId
    , apiGet
    , authorizationUrl
    , decodeUserId
    , getOwnUser
    , getUserBlockList
    , getUserByLogin
    )

import Array
import Http exposing (header, request)
import Json.Decode as Decode exposing (Decoder, array, field)
import Url.Builder exposing (crossOrigin, string)


type alias AccessToken =
    String


type alias UserId =
    String


baseUrl : String
baseUrl =
    "https://api.twitch.tv/helix"


clientId : String
clientId =
    "o114479h5askdxyakpic86pvutfd4m"


auth : AccessToken -> Http.Header
auth accessToken =
    header "Authorization" <| "Bearer " ++ accessToken


scopes : List String
scopes =
    [ --"user_subscriptions"
      -- , "user_blocks_edit"
      -- , -- deprecated, replaced with "user:read:blocked_users"
      --   "user_follows_edit"
      -- , -- deprecated, soon to be removed later since we now use "user:edit:follows"
      --   "channel_editor"
      -- , -- for /raid
      --   "channel:moderate"
      -- , "channel:read:redemptions"
      -- , "chat:edit"
      -- , "chat:read"
      -- , "whispers:read"
      -- , "whispers:edit"
      -- , "channel_commercial"
      -- , -- for /commercial
      --   "channel:edit:commercial"
      -- , -- in case twitch upgrades things in the future (and this scope is required)
      --   "user:edit:follows"
      -- , -- for (un)following
      --   "clips:edit"
      -- , -- for clip creation
      --   "channel:manage:broadcast"
      -- , -- for creating stream markers with /marker command, and for the /settitle and /setgame commands
      "user:read:blocked_users"

    -- , -- for getting list of blocked users
    --   "user:manage:blocked_users" -- for blocking/unblocking other users
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


{-| Extracts the user id from the twitch get user response.
-}
decodeUserId : Decoder String
decodeUserId =
    field "data" (array (field "id" Decode.string))
        |> Decode.map (Array.get 0 >> Maybe.withDefault "")


apiGet : String -> Http.Expect msg -> AccessToken -> Cmd msg
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


getOwnUser : String
getOwnUser =
    crossOrigin baseUrl [ "users" ] []


getUserByLogin : String -> String
getUserByLogin name =
    crossOrigin baseUrl [ "users" ] [ string "login" name ]


getUserBlockList : String -> String
getUserBlockList broadcasterId =
    crossOrigin baseUrl [ "users", "blocks" ] [ string "broadcaster_id" broadcasterId ]
