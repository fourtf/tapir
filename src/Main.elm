module Main exposing (main)

import Api exposing (apiGet)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Common exposing (Model, Msg(..), Route(..))
import Helper exposing (authFragment, httpErrorToString)
import Http
import JsonTree
import Url exposing (Url)
import Url.Parser exposing ((</>))
import View exposing (viewBody)


defaultModel : Key -> Model
defaultModel key =
    { route = RouteHome
    , accessToken = Nothing
    , key = key
    , selectedUser = ""
    , result = ""
    , resultParsed = JsonTree.parseString "{}"
    , resultTreeState = JsonTree.defaultState
    }


type alias Flags =
    {}


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }


{-| Redirect and set access\_token if /auth is called directly with a token
-}
init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        m =
            defaultModel key

        r =
            route url
    in
    case r of
        RouteAuth (Just auth) ->
            ( { m | accessToken = Just auth.access_token }, Nav.replaceUrl key "/" )

        _ ->
            ( { m | route = r }
            , Cmd.none
            )


view : Model -> Browser.Document Msg
view model =
    { title = "API Explorer for Twitch"
    , body = viewBody model
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MsgUrlRequest (External url) ->
            ( model, Nav.load url )

        MsgUrlRequest (Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        ChangeRoute r ->
            ( { model | route = r }, Cmd.none )

        SetAccessToken token ->
            ( { model | accessToken = Just token }, Nav.replaceUrl model.key "/" )

        NopMsg ->
            ( model, Cmd.none )

        SetSelectedUser user ->
            ( { model | selectedUser = user }, Cmd.none )

        ApiFetchUserByLogin user ->
            ( model
            , apiGet (Api.getUserByLogin user) (Http.expectString ApiResult) (Maybe.withDefault "" model.accessToken)
            )

        ApiResult (Ok val) ->
            ( updateResult model val, Cmd.none )

        ApiResult (Err err) ->
            ( { model | result = httpErrorToString err }, Cmd.none )

        SetTreeViewState state ->
            ( { model | resultTreeState = state }, Cmd.none )


updateResult : Model -> String -> Model
updateResult model json =
    { model
        | result = json
        , resultParsed = JsonTree.parseString json
        , resultTreeState = JsonTree.defaultState
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


onUrlRequest : UrlRequest -> Msg
onUrlRequest =
    MsgUrlRequest


{-| the page needs to be reloaded when auth changes so we don't need to handle it here but in `init` instead
-}
onUrlChange : Url -> Msg
onUrlChange =
    route >> ChangeRoute


route : Url -> Route
route =
    Url.Parser.parse parseRoute
        >> Maybe.withDefault Route404


parseRoute : Url.Parser.Parser (Route -> c) c
parseRoute =
    Url.Parser.oneOf
        [ Url.Parser.map RouteHome Url.Parser.top
        , Url.Parser.map RouteAuth (Url.Parser.s "auth" </> Url.Parser.fragment (Maybe.andThen authFragment))
        ]
