module Main exposing (..)

import Html exposing (Html, Attribute, programWithFlags, text, div, input, h2, button, a, br, p, blockquote, node)
import Html.Events exposing (on, keyCode, onClick, onInput)
import Html.Attributes exposing (value, charset, src, id, href, dir, attribute, placeholder, property, class, style)
import Json.Decode exposing (Decoder)
import Json.Encode
import Http exposing (Error)
import Dict exposing (Dict)
import Task
import Svg
import Svg.Attributes
import Dom


main : Program NounList Model Msg
main =
    programWithFlags { view = view, init = init, update = update, subscriptions = always Sub.none }


type alias NounList =
    List String


type alias Query =
    String


type State
    = Starting
    | Playing { searchQuery : String }
    | Loading Query
    | Win
    | Lose


type alias Cache =
    Dict ( String, GitHubSearchResult )


type alias Model =
    { state : State, nouns : NounList, cache : Maybe Cache }


init : NounList -> ( Model, Cmd Msg )
init nouns =
    ( Model Starting nouns Nothing, Cmd.none )


initPlaying : State
initPlaying =
    Playing { searchQuery = "" }


type Msg
    = NoOp
    | Send
    | HandleResponse (Result Error GitHubSearchResult)
    | UpdateSearchQuery String
    | InputKeyDown Int
    | StartGame


makeSearchUrl : String -> String
makeSearchUrl query =
    query
        |> String.trim
        |> Http.encodeUri
        |> (++) "https://api.github.com/search/repositories?q="
        |> flip (++) "+language:javascript"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        { state } =
            model
    in
        case ( state, msg ) of
            ( _, StartGame ) ->
                ( { model | state = initPlaying }
                , Task.attempt (always NoOp) (Dom.focus "search-input")
                )

            ( Playing data, _ ) ->
                case msg of
                    Send ->
                        if String.length data.searchQuery > 0 then
                            ( { model | state = Loading data.searchQuery }
                            , Http.send HandleResponse <|
                                Http.get (makeSearchUrl data.searchQuery) gitHubSearchResultDecoder
                            )
                        else
                            ( model, Cmd.none )

                    UpdateSearchQuery value ->
                        ( { model | state = Playing { data | searchQuery = value } }
                        , Cmd.none
                        )

                    InputKeyDown code ->
                        case code of
                            13 ->
                                update Send model

                            _ ->
                                ( model, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

            ( Loading query, HandleResponse searchRes ) ->
                case searchRes of
                    Ok data ->
                        if data.total_count > 0 then
                            ( { model | state = Win }, Cmd.none )
                        else
                            ( { model | state = Lose }, Cmd.none )

                    Err reason ->
                        ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )


type alias GitHubSearchResultItem =
    { name : String
    , url : String
    }


type alias GitHubSearchResult =
    { total_count : Int, items : List GitHubSearchResultItem }


gitHubSearchResultItemDecoder : Decoder GitHubSearchResultItem
gitHubSearchResultItemDecoder =
    Json.Decode.map2
        GitHubSearchResultItem
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "url" Json.Decode.string)


gitHubSearchResultDecoder : Decoder GitHubSearchResult
gitHubSearchResultDecoder =
    Json.Decode.map2
        GitHubSearchResult
        (Json.Decode.field "total_count" Json.Decode.int)
        (Json.Decode.field "items" <| Json.Decode.list gitHubSearchResultItemDecoder)


view : Model -> Html Msg
view { state } =
    div
        []
        [ viewForkMe "https://github.com/halfzebra/drinking-game-for-web-devs"
        , case state of
            Starting ->
                div
                    [ class "fade-in" ]
                    [ div [ style [ ( "max-height", "250px" ), ( "overflow", "hidden" ) ] ] [ tweet ]
                    , button [ onClick StartGame, class "button" ] [ text "Start" ]
                    ]

            Playing data ->
                div [ class "fade-in" ]
                    [ input
                        [ onInput UpdateSearchQuery
                        , onKeyDown InputKeyDown
                        , value data.searchQuery
                        , class "search-input"
                        , id "search-input"
                        , placeholder <| String.toUpper "Type the noun"
                        ]
                        []
                    , button [ onClick Send, class "button" ] [ text "Search" ]
                    ]

            Loading _ ->
                div [] [ loadingIcon ]

            Win ->
                div
                    [ class "fade-in" ]
                    [ h2
                        []
                        [ text "You have won the game!" ]
                    , button [ onClick StartGame, class "button" ] [ text "Try again" ]
                    ]

            Lose ->
                div
                    [ class "fade-in" ]
                    [ text "You have lost the game", button [ onClick StartGame, class "button" ] [ text "Try again" ] ]
        ]


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.Decode.map tagger keyCode)


lang : String -> Attribute Msg
lang =
    attribute "lang"


dataLang : String -> Attribute Msg
dataLang =
    attribute "data-lang"


script : List (Attribute msg) -> List (Html msg) -> Html msg
script =
    node "script"


tweet : Html Msg
tweet =
    div
        []
        [ div
            [ property "innerHTML" (Json.Encode.string """
                <blockquote class="twitter-tweet" data-lang="en">
                    <p lang="en" dir="ltr">Drinking game for web devs:
                        <br>(1) Think of a noun
                        <br>(2) Google &quot;&lt;noun&gt;.js&quot;
                        <br>(3) If a library with that name exists - drink
                    </p>&mdash; Shay Friedman (@ironshay)
                    <a href="https://twitter.com/ironshay/status/370525864523743232">
                        August 22, 2013
                    </a>
                </blockquote>
            """) ]
            []
        ]


viewForkMe : String -> Html Msg
viewForkMe url =
    a
        [ attribute "aria-label" "View source on Github"
        , class "github-corner"
        , href url
        ]
        [ Svg.svg
            [ attribute "aria-hidden" "true"
            , Svg.Attributes.height "80"
            , Svg.Attributes.style "fill:#60B5CC; color:#34495E; position: absolute; top: 0; border: 0; right: 0;"
            , Svg.Attributes.viewBox "0 0 250 250"
            , Svg.Attributes.width "80"
            ]
            [ Svg.path
                [ Svg.Attributes.d "M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z" ]
                []
            , Svg.path
                [ Svg.Attributes.class "octo-arm"
                , Svg.Attributes.d "M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2"
                , Svg.Attributes.fill "currentColor"
                , Svg.Attributes.style "transform-origin: 130px 106px;"
                ]
                []
            , Svg.path
                [ Svg.Attributes.class "octo-body"
                , Svg.Attributes.d "M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.4 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.8 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z"
                , Svg.Attributes.fill "currentColor"
                ]
                []
            ]
        ]


xmlns =
    attribute "xmlns" "http://www.w3.org/2000/svg"


xmlnsXlink =
    attribute "xmlns:xlink" "http://www.w3.org/1999/xlink"


xmlSpace =
    attribute "xml:space"


loadingIcon =
    Svg.svg
        [ Svg.Attributes.version "1.1"
        , Svg.Attributes.id "loader-1"
        , xmlns
        , xmlnsXlink
        , Svg.Attributes.x "0px"
        , Svg.Attributes.y "0px"
        , Svg.Attributes.width "200px"
        , Svg.Attributes.height "200px"
        , Svg.Attributes.viewBox "0 0 40 40"
        , Svg.Attributes.enableBackground "new 0 0 40 40"
        , Svg.Attributes.xmlSpace "preserve"
        ]
        [ Svg.path
            [ Svg.Attributes.opacity "0.2"
            , Svg.Attributes.fill "#FFFFFF"
            , Svg.Attributes.d "M20.201,5.169c-8.254,0-14.946,6.692-14.946,14.946c0,8.255,6.692,14.946,14.946,14.946s14.946-6.691,14.946-14.946C35.146,11.861,28.455,5.169,20.201,5.169z M20.201,31.749c-6.425,0-11.634-5.208-11.634-11.634c0-6.425,5.209-11.634,11.634-11.634c6.425,0,11.633,5.209,11.633,11.634C31.834,26.541,26.626,31.749,20.201,31.749z"
            ]
            []
        , Svg.path
            [ Svg.Attributes.fill "#FFFFFF"
            , Svg.Attributes.d "M26.013,10.047l1.654-2.866c-2.198-1.272-4.743-2.012-7.466-2.012h0v3.312h0C22.32,8.481,24.301,9.057,26.013,10.047z"
            , Svg.Attributes.transform "rotate(264 20 20)"
            ]
            [ Svg.animateTransform
                [ Svg.Attributes.attributeType "xml"
                , Svg.Attributes.attributeName "transform"
                , Svg.Attributes.type_ "rotate"
                , Svg.Attributes.from "0 20 20"
                , Svg.Attributes.to "360 20 20"
                , Svg.Attributes.dur "1.0s"
                , Svg.Attributes.repeatCount "indefinite"
                ]
                []
            ]
        ]
