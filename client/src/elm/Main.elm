module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import WebSocket
import Html.Events exposing (onClick)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)



-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Player
    = Red
    | Black


type alias Spot =
    Maybe Player


type GameState
    = Waiting
    | Going Player
    | Done Player


type alias Model =
    { state : GameState
    , board : List (List Spot)
    , me : Player
    }


boardDims : { rows : Int, cols : Int }
boardDims =
    { rows = 6, cols = 7 }


maxWidth : Int
maxWidth =
    700


squareSide : Int
squareSide =
    maxWidth // boardDims.cols


init : ( Model, Cmd Msg )
init =
    let
        rows =
            boardDims.rows

        cols =
            boardDims.cols

        board =
            List.repeat cols (List.repeat rows Nothing)
    in
        ( Model Waiting board Black, Cmd.none )


serverUrl : String
serverUrl =
    "ws://127.0.0.1:8000/game/"


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen serverUrl SocketMessage



-- UPDATE


type alias Move =
    Int


type Msg
    = NoOp
    | PlayerMove Move
    | SocketMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        NoOp ->
            model ! []

        SocketMessage str ->
            case Debug.log "ws" str of
                "WAIT" ->
                    { model | state = Waiting, me = Red } ! []

                "START" ->
                    { model | state = Going Red } ! []

                _ ->
                    model ! []

        PlayerMove mv ->
            ( model, mv |> toString |> WebSocket.send serverUrl )



-- VIEW
-- Html is defined as: elem [ attribs ][ children ]
-- CSS can be applied via class names or inline style attrib


view : Model -> Html Msg
view model =
    div
        [ class "container"
        , style
            [ "margin-top" => "30px"
            ]
        ]
        [ board model.board
        , button [ class "btn btn-primary btn-lg", onClick (PlayerMove 2) ] []
        ]


board : List (List Spot) -> Html Msg
board spotGrid =
    let
        boardRow i col =
            div [ style [ "width" => (px maxWidth) ] ] (List.indexedMap (boardSpot i) col)
    in
        div [ style [ ("position" => "relative") ] ] <|
            List.indexedMap
                boardRow
                spotGrid


px : Int -> String
px =
    toString >> (\x -> x ++ "px")


boardSpot : Int -> Int -> Spot -> Html Msg
boardSpot i j spot =
    let
        color =
            case spot of
                Just player ->
                    case player of
                        Black ->
                            "black"

                        Red ->
                            "red"

                Nothing ->
                    "white"

        factor =
            (*) 100
    in
        div
            [ style
                [ "background" => color
                , "width" => "100px"
                , "height" => "100px"
                , "position" => "absolute"
                , "left" => (i |> factor |> px)
                , "top" => (j |> factor |> px)
                , "outline" => "1px solid"
                ]
            , onClick (PlayerMove i)
            ]
            []
