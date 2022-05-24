module Main exposing (main)

import Api exposing (apiGet, getOwnUser)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Common exposing (Api(..), Model, Msg(..), Route(..))
import Helper exposing (authFragment, httpErrorToString)
import Http
import JsonTree
import Url exposing (Url)
import Url.Parser exposing ((</>))
import View


defaultModel : Key -> Model
defaultModel key =
    { route = RouteHome
    , myUserId = ""
    , accessToken = Nothing
    , key = key
    , result = Nothing
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
            ( m, continueAuth auth.accessToken )

        _ ->
            -- discard the original route, go straight to auth request page
            ( { m | route = RouteRequestAuth }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "API Explorer for Twitch"
    , body = View.view model
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NopMsg ->
            ( model, Cmd.none )

        -- Auth
        Authorize accessToken uid ->
            ( { model | accessToken = Just accessToken, myUserId = uid }
            , Nav.replaceUrl model.key "/"
            )

        -- Application Lifecycle
        MsgUrlRequest (External url) ->
            ( model, Nav.load url )

        MsgUrlRequest (Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        ChangeRoute r ->
            ( { model | route = r, result = Nothing }, Cmd.none )

        ChangeApiRoute api ->
            ( { model | route = RouteApi api }, Cmd.none )

        -- Api Stuff
        FetchApi url ->
            ( model
            , apiGet url (Http.expectString ApiResult) (Maybe.withDefault "" model.accessToken)
            )

        ApiResult (Ok val) ->
            ( updateResult model val, Cmd.none )

        ApiResult (Err err) ->
            ( { model
                | result = Just <| Err <| httpErrorToString err
                , resultTreeState = JsonTree.defaultState
              }
            , Cmd.none
            )

        SetTreeViewState state ->
            ( { model | resultTreeState = state }, Cmd.none )


updateResult : Model -> String -> Model
updateResult model json =
    { model
        | result =
            Just <|
                Ok
                    { json = json
                    , parsed = JsonTree.parseString json
                    }
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
        [ Url.Parser.top |> Url.Parser.map RouteHome
        , (Url.Parser.s "auth" </> Url.Parser.fragment (Maybe.andThen authFragment)) |> Url.Parser.map RouteAuth
        , Url.Parser.s "get-users-by-login" |> Url.Parser.map (RouteApi <| GetUserByLogin "")
        , Url.Parser.s "get-my-blocks" |> Url.Parser.map (RouteApi <| GetMyBlockedUsers)
        ]


continueAuth : Api.AccessToken -> Cmd Msg
continueAuth accessToken =
    apiGet
        getOwnUser
        (Http.expectJson
            (Result.map (Authorize accessToken) >> Result.withDefault NopMsg)
            Api.decodeUserId
        )
        accessToken
