module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import WebSocket
import Html.Events exposing (onClick)
import List.Extra exposing ((!!))


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


grabAt : Int -> List a -> List a
grabAt i =
    List.drop i >> List.take 1


rangex : Int -> Int -> List Int
rangex lo hi =
    List.range lo (hi - 1)



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



--getDiagonals : List (List a) -> List (List a)


getDiagonals : List (List a) -> List (List a)
getDiagonals grid =
    let
        nrows =
            List.head grid |> Maybe.withDefault [] |> List.length

        ncols =
            List.length grid

        starts =
            List.Extra.lift2 (,) (rangex 0 ncols) (rangex 0 nrows)

        diag xs ys =
            List.map2
                (\x y -> grid !! x |> Maybe.withDefault [] |> grabAt y)
                xs
                ys
                |> List.concat

        -- Two kinds of diags, down-right and upRight
        diags isReversed =
            starts
                |> List.map
                    (\( col, row ) ->
                        diag (rangex col ncols)
                            (rangex row nrows
                                |> if isReversed then
                                    List.reverse
                                   else
                                    identity
                            )
                    )

        upRight =
            diags True

        downRight =
            diags False
    in
        upRight ++ downRight


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
                >> (\l ->
                        -- Is this a list of nothings?
                        case List.head l of
                            Just Nothing ->
                                []

                            _ ->
                                l
                   )
                >> List.length
                >> (==) 4

        diagonals =
            getDiagonals model.board

        checkAll =
            [ rows, columns, diagonals ]
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
            [ "margin" => "30px"
            ]
        ]
        [ banner model
        , board model.board
        , button [ class "btn btn-primary btn-lg", onClick (PlayerMove 2) ] []
        ]


banner : Model -> Html Msg
banner model =
    let
        words =
            case model.state of
                Waiting ->
                    "Waiting for opponent to join"

                Going ->
                    if model.player == model.me then
                        "Your turn"
                    else
                        "Opponent's turn"

                Done p ->
                    if p == model.me then
                        "You win!"
                    else
                        "Opponent wins!"
    in
        div [] [ text words ]


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
