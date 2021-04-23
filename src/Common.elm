module Common exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Helper exposing (AuthFragment)
import Http
import Json.Decode as Decode
import JsonTree


type alias Model =
    { route : Route
    , accessToken : Maybe String
    , key : Key
    , selectedUser : String
    , result : String
    , resultParsed : Result Decode.Error JsonTree.Node
    , resultTreeState : JsonTree.State
    }


type Msg
    = NopMsg
    | MsgUrlRequest UrlRequest
    | ChangeRoute Route
    | SetAccessToken String
    | SetSelectedUser String
    | ApiFetchUserByLogin String
    | ApiResult (Result Http.Error String)
    | SetTreeViewState JsonTree.State


type Route
    = RouteHome
    | Route404
    | RouteAuth (Maybe AuthFragment)
