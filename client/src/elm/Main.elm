module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import WebSocket
import Html.Events exposing (onClick)
import List.Extra


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
    | Going
    | Done Player


type alias Model =
    { state : GameState
    , board : List (List Spot)
    , me : Player
    , player : Player
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
        ( Model Waiting board Black Red, Cmd.none )


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
                    { model | state = Going } ! []

                _ ->
                    (model |> doMove str) ! []

        PlayerMove mv ->
            ( model, mv |> toString |> WebSocket.send serverUrl )


doMove : String -> Model -> Model
doMove colStr model =
    let
        colIndex =
            String.toInt colStr |> Result.withDefault 0

        newBoard =
            model.board
                |> List.indexedMap
                    (\i col ->
                        if i == colIndex then
                            newColumn col
                        else
                            col
                    )

        flipPlayer model =
            { model
                | player =
                    case model.player of
                        Red ->
                            Black

                        Black ->
                            Red
            }

        newColumn column =
            List.Extra.span ((==) Nothing) column
                |> \( ns, js ) -> (List.drop 1 ns) ++ (Just model.player :: js)
    in
        { model | board = newBoard }
            |> checkWinner
            |> flipPlayer


checkWinner : Model -> Model
checkWinner model =
    let
        columns =
            model.board

        rows =
            List.Extra.transpose model.board

        checkIt =
            List.Extra.group
                >> List.Extra.maximumBy List.length
                >> Maybe.withDefault []
                >> List.filter ((/=) Nothing)
                >> List.length
                >> (==) 4

        checkAll =
            [ rows, columns ]
                |> List.map (List.any checkIt)
                |> List.any ((==) True)
    in
        if checkAll then
            { model | state = Done model.player }
        else
            model



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
        div [ style [ ("position" => "relative") ] ]
            (List.indexedMap
                boardRow
                spotGrid
            )


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
