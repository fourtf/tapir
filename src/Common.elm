module Common exposing (..)

import Api exposing (AccessToken, UserId)
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Helper exposing (AuthFragment)
import Http
import Json.Decode as Decode
import JsonTree


type alias Model =
    { route : Route
    , accessToken : Maybe AccessToken
    , myUserId : UserId
    , key : Key
    , result : Maybe (Result String ResultModel)
    , resultTreeState : JsonTree.State
    }


type alias ResultModel =
    { json : String
    , parsed : Result Decode.Error JsonTree.Node
    }


type Msg
    = NopMsg
      -- Auth
    | Authorize AccessToken UserId
      -- Application Lifecycle
    | MsgUrlRequest UrlRequest
    | ChangeRoute Route
    | ChangeApiRoute Api
      -- Api Stuff
    | FetchApi String
    | ApiResult (Result Http.Error String)
    | SetTreeViewState JsonTree.State


type Route
    = RouteHome
    | Route404
    | RouteAuth (Maybe AuthFragment)
    | RouteApi Api


type Api
    = GetUserByLogin String
    | GetMyBlockedUsers
