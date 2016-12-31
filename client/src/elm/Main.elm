module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import WebSocket
import Html.Events exposing (onClick)


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
    , me : Maybe Player
    }


boardDims : ( Int, Int )
boardDims =
    ( 6, 7 )


init : ( Model, Cmd Msg )
init =
    let
        rows =
            Tuple.first boardDims

        cols =
            Tuple.second boardDims

        board =
            List.repeat rows (List.repeat cols Nothing)
    in
        ( Model Waiting board Nothing, Cmd.none )


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
            , "width" => "700px"
            ]
        ]
        [ board model.board
        , button [ class "btn btn-primary btn-lg", onClick (PlayerMove 2) ] []
        ]


board : List (List Spot) -> Html Msg
board spotGrid =
    div [] <|
        List.map
            (\row -> div [ style [ "width" => "700px" ] ] (List.map boardSpot row))
            spotGrid


boardSpot : Spot -> Html Msg
boardSpot spot =
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
    in
        div
            [ style
                [ "background" => color
                , "width" => "100px"
                , "height" => "100px"
                , "float" => "left"
                , "outline" => "1px solid"
                ]
            ]
            []



-- CSS STYLES


styles : { img : List ( String, String ) }
styles =
    { img =
        [ ( "width", "33%" )
        , ( "border", "4px solid #337AB7" )
        ]
    }
