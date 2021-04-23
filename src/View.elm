module View exposing (viewBody)

import Api exposing (authorizationUrl)
import Browser exposing (UrlRequest(..))
import Common exposing (Model, Msg(..), Route(..))
import Html exposing (a, button, div, input, span, text)
import Html.Attributes exposing (href, placeholder, style, value)
import Html.Events exposing (onClick, onInput)
import JsonTree
import Url.Parser exposing ((</>))


font : String
font =
    "\"Segoe UI\", Verdana, Arial, Helvetica, sans-serif"


navBg : String
navBg =
    "#2E125B"


textColor : String
textColor =
    "#eee"


linkColor : String
linkColor =
    "#93C5FD"


siteBg : String
siteBg =
    -- "#064E3B"
    "#0F061E"


link : String -> String -> Html.Html msg
link linkHref linkText =
    a [ href linkHref, style "color" linkColor, spacedStyle ] [ text linkText ]


spacedStyle : Html.Attribute msg
spacedStyle =
    style "margin" "0 8px"


spaced : Html.Html msg -> Html.Html msg
spaced child =
    span [ style "margin" "0 8px 0 0" ] [ child ]


viewBody : Model -> List (Html.Html Msg)
viewBody model =
    case model.route of
        RouteHome ->
            [ div
                [ style "background" siteBg
                , style "min-height" "100vh"
                , style "color" textColor
                , style "font-family" font
                ]
                (viewPage
                    model
                 <|
                    div
                        [ style "overflow-x" "auto"
                        , style "padding" "16px"
                        ]
                        [ text "Get User by Login:"
                        , viewGetUser model
                        , text "Result:"
                        , case model.resultParsed of
                            Ok root ->
                                JsonTree.view root
                                    { colors =
                                        { string = "#6EE7B7"
                                        , number = "#93C5FD"
                                        , bool = "#F9A8D4"
                                        , null = "#D1D5DB"
                                        , selectable = "#FBBF24"
                                        }
                                    , onSelect = Nothing
                                    , toMsg = SetTreeViewState
                                    }
                                    model.resultTreeState

                            Err _ ->
                                text "json error xd"
                        ]
                )
            ]

        Route404 ->
            [ text "404" ]

        RouteAuth Nothing ->
            [ text "auth nothing" ]

        RouteAuth (Just auth) ->
            [ text auth.access_token, text auth.scope ]


viewPage : Model -> Html.Html Msg -> List (Html.Html Msg)
viewPage model content =
    [ viewHeader model
    , content
    , viewFooter
    ]


viewHeader : Model -> Html.Html Msg
viewHeader model =
    div
        [ style "background" navBg
        , style "padding" "8px 8px"
        ]
        [ spaced <| text "Twitch API Explorer"
        , link authorizationUrl "Authorize with Twitch"
        , span [ spacedStyle ]
            [ text <|
                if model.accessToken == Nothing then
                    "not authorized"

                else
                    "authorized"
            ]
        ]


viewFooter : Html.Html Msg
viewFooter =
    div []
        [-- text "Made by fourtf"
        ]


viewGetUser : Model -> Html.Html Msg
viewGetUser model =
    div []
        [ spaced <| text "User login:"
        , spaced <|
            input
                [ placeholder "user login"
                , value model.selectedUser
                , onInput SetSelectedUser
                ]
                []
        , spaced <|
            button
                [ onClick (ApiFetchUserByLogin model.selectedUser)
                ]
                [ text "fetch" ]
        ]
