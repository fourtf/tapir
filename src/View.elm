module View exposing (view)

import Api exposing (authorizationUrl, getUserBlockList, getUserByLogin)
import Browser exposing (UrlRequest(..))
import Common exposing (Api(..), Model, Msg(..), Route(..))
import Element exposing (Attribute, Color, Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, layout, link, maximum, padding, paddingEach, paddingXY, px, rgb, rgb255, rgba, row, scrollbarX, spacing, text, width, wrappedRow)
import Element.Background
import Element.Border exposing (rounded)
import Element.Font as Font exposing (center)
import Element.Input exposing (button, labelHidden, labelLeft, placeholder)
import Helper exposing (onEnter)
import Html
import Html.Attributes exposing (style)
import JsonTree
import List exposing (minimum)
import Url.Parser exposing ((</>))



-- CONFIG FUNCTIONS


siteFont : List Font.Font
siteFont =
    [ Font.external { name = "Inter", url = "https://fonts.googleapis.com/css2?family=Inter:wght@300;400&display=swap" }
    , Font.sansSerif
    ]


navBg : String
navBg =
    "#262626"


textColor : String
textColor =
    "#eee"


cardTitleColor : String
cardTitleColor =
    "#c8c8c8"


linkColor : String
linkColor =
    "#93C5FD"


siteBg : String
siteBg =
    "#292C30"


bgHex : String -> Attribute Msg
bgHex s =
    htmlAttribute <| style "background" s


fgHex : String -> Attribute Msg
fgHex s =
    htmlAttribute <| style "color" s


defaultShadow : Attribute Msg
defaultShadow =
    htmlAttribute <| style "box-shadow" "0px 4px 8px rgba(0, 0, 0, 0.25)"


whiteBorder : List (Attribute Msg)
whiteBorder =
    [ Element.Border.solid
    , Element.Border.color <| rgba 1 1 1 0.25
    , Element.Border.width 1
    ]


twitchHex : String
twitchHex =
    "#9256ED"


primaryButtonAttr : List (Attribute Msg)
primaryButtonAttr =
    whiteBorder
        ++ [ bgHex twitchHex
           , fgHex "#ffffff"
           , padding 10
           , rounded 6
           , Font.center
           ]


bodyAttrs : List (Attribute Msg)
bodyAttrs =
    [ htmlAttribute <| style "min-height" "100vh", bgHex siteBg, Font.family siteFont, Font.size 16, fgHex textColor ]



-- VIEW


view : Model -> List (Html.Html Msg)
view model =
    (List.singleton << layout bodyAttrs) <|
        case model.route of
            RouteRequestAuth ->
                column
                    [ centerX, centerY, center, spacing 16 ]
                    [ text "Authorize with twitch to use this page."
                    , link (centerX :: primaryButtonAttr) { url = authorizationUrl, label = text "Authorize with Twitch" }
                    ]

            RouteHome ->
                authorized <| el [ centerX ] <| text "Select an endpoint."

            RouteApi api ->
                authorized <| viewApi model api

            Route404 ->
                authorized <| text "404"

            RouteAuth Nothing ->
                link [] { url = "/", label = text "go to home" }

            RouteAuth (Just _) ->
                text "You shouldn't be seeing this. Try reloading the page."


authorized : Element Msg -> Element Msg
authorized content =
    column [ width fill, centerX ] [ nav, content ]



-- ITEMS


nav : Element Msg
nav =
    let
        menuLink url label =
            el
                [ padding 24 ]
                (link [] { url = url, label = text label })
    in
    wrappedRow [ centerX ]
        [ row [ fgHex "#aaa" ] [ el [ fgHex twitchHex ] <| text "T", text "APIr" ]
        , menuLink "get-users-by-login" "Get Users by Login"
        , menuLink "get-my-blocks" "Get Blocked Users"
        ]


viewApi : Model -> Api -> Element Msg
viewApi model api =
    column
        [ width fill, padding 30, spacing 30 ]
        [ viewQuery model api
        , viewResult model
        ]


card : List (Attribute Msg) -> Element Msg -> Element Msg
card attr content =
    el
        (attr
            ++ whiteBorder
            ++ [ bgHex "#202020"
               , paddingXY 20 20
               , rounded 12
               , defaultShadow
               , width fill
               ]
        )
        content


cardTitle : String -> Element Msg
cardTitle title =
    el
        [ paddingEach { top = 0, left = 0, right = 0, bottom = 20 }
        ]
        (el [ Font.family siteFont, Font.size 16, fgHex cardTitleColor, Font.light ] <| text title)


viewQuery : Model -> Api -> Element Msg
viewQuery model api =
    card [ centerX, width fill ] <|
        column []
            [ cardTitle "Query"
            , case api of
                GetUserByLogin username ->
                    column []
                        [ -- text "Get User by Login:"
                          viewGetUser username
                        ]

                GetMyBlockedUsers ->
                    column []
                        [ --text "Get my blocked users."
                          button []
                            { onPress = Just <| FetchApi <| getUserBlockList model.myUserId
                            , label = text "Go!"
                            }
                        ]
            ]


viewResult : Model -> Element Msg
viewResult model =
    case model.result of
        Just (Ok { parsed }) ->
            case parsed of
                Ok root ->
                    card [] <|
                        column
                            [ htmlAttribute <| Html.Attributes.style "max-width" "calc(100vw - 120px)"
                            , htmlAttribute <| Html.Attributes.style "overflow-x" "auto"
                            , htmlAttribute <| Html.Attributes.style "overflow-y" "clip"
                            ]
                            [ cardTitle "Result"
                            , JsonTree.view
                                root
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
                                |> html
                            ]

                Err _ ->
                    text "error decoding json"

        Just (Err errStr) ->
            text errStr

        Nothing ->
            text "no result yet"


myInput : String -> String -> (String -> Msg) -> Element Msg
myInput label text onChange =
    el [ bgHex "#393939" ] <|
        Element.Input.text
            (whiteBorder
                ++ [ Element.Background.color <| rgb255 57 57 57
                   , fgHex "#ffffff"
                   , padding 10
                   , rounded 6
                   , width <| px 200
                   ]
            )
            { placeholder = Nothing
            , text = text
            , label = labelHidden label
            , onChange = onChange
            }


goButton : Msg -> Element Msg
goButton msg =
    row [ width fill ]
        [ button
            (Element.alignRight :: width (px 95) :: primaryButtonAttr)
            { onPress = Just msg
            , label = text "Go!"
            }
        ]


viewGetUser : String -> Element Msg
viewGetUser username =
    column [ spacing 16, onEnter <| FetchApi <| getUserByLogin username ]
        [ row [ spacing 8 ]
            [ text "User login:"
            , myInput "User login:" username (GetUserByLogin >> ChangeApiRoute)
            ]
        , goButton <| FetchApi <| getUserByLogin username
        ]
