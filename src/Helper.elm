module Helper exposing (..)

import Http


stringSplitPair : String -> String -> Maybe ( String, String )
stringSplitPair pat input =
    String.indices pat input
        |> List.head
        |> Maybe.map
            (\i ->
                ( String.left i input, String.dropLeft (i + String.length pat) input )
            )


type alias AuthFragment =
    { access_token : String, scope : String }


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
        (\access_token scope ->
            { access_token = access_token, scope = scope }
        )
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
