module Helper exposing (..)

import Api exposing (AccessToken)
import Element
import Html.Events
import Http
import Json.Decode as Decode


stringSplitPair : String -> String -> Maybe ( String, String )
stringSplitPair pat input =
    String.indices pat input
        |> List.head
        |> Maybe.map
            (\i ->
                ( String.left i input, String.dropLeft (i + String.length pat) input )
            )


type alias AuthFragment =
    { accessToken : AccessToken, scope : String }


authFragment : String -> Maybe AuthFragment
authFragment val =
    let
        params =
            String.split "&" val
                |> List.map (stringSplitPair "=")
                |> List.filterMap identity

        getValue key =
            List.filter (\x -> Tuple.first x == key) params |> List.head |> Maybe.map Tuple.second
    in
    Maybe.map2
        AuthFragment
        (getValue "access_token")
        (getValue "scope")


httpErrorToString : Http.Error -> String
httpErrorToString err =
    "error: "
        ++ (case err of
                Http.BadUrl msg ->
                    "bad url: " ++ msg

                Http.Timeout ->
                    "timeout"

                Http.NetworkError ->
                    "network error"

                Http.BadStatus code ->
                    "status " ++ String.fromInt code

                Http.BadBody msg ->
                    "error message " ++ msg
           )


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )
