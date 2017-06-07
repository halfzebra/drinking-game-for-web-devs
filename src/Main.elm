module Main exposing (..)

import Html
    exposing
        ( Html
        , Attribute
        , programWithFlags
        , text
        , div
        , input
        , h2
        , button
        , a
        , br
        , pg
        , blockquote
        , node
        )
import Html.Events exposing (on, keyCode, onClick, onInput)
import Html.Attributes
    exposing
        ( value
        , charset
        , async
        , src
        , id
        , href
        , dir
        , attribute
        , placeholder
        , property
        , class
        , style
        )
import Json.Decode exposing (Decoder)
import Json.Encode
import Http exposing (Error)
import Dict exposing (Dict)
import Task
import Dom
import Icons exposing (loadingIcon, forkMeIcon)


main : Program (List String) Model Msg
main =
    programWithFlags
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }


type State
    = Starting
    | Playing
    | Loading
    | Win
    | Lose
    | Error Http.Error


type alias Model =
    { query : String, state : State, nouns : List String, cache : Dict String GitHubSearchResult }


init : List String -> ( Model, Cmd Msg )
init nouns =
    ( Model "" Starting nouns Dict.empty, Cmd.none )


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


focus : String -> Cmd Msg
focus id =
    Task.attempt (always NoOp) (Dom.focus id)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        { state } =
            model
    in
        case ( state, msg ) of
            ( _, StartGame ) ->
                ( { model | query = "", state = Playing }
                , focus "search-input"
                )

            ( Playing, _ ) ->
                case msg of
                    Send ->
                        if String.length model.query > 0 then
                            ( { model | state = Loading }
                            , Http.send HandleResponse <|
                                Http.get (makeSearchUrl model.query) gitHubSearchResultDecoder
                            )
                        else
                            ( model, focus "search-input" )

                    UpdateSearchQuery value ->
                        ( { model | state = Playing, query = value }
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

            ( Loading, HandleResponse searchRes ) ->
                case searchRes of
                    Ok data ->
                        if data.totalCount > 0 then
                            ( { model
                                | state = Lose
                                , cache = Dict.insert model.query data model.cache
                              }
                            , Cmd.none
                            )
                        else
                            ( { model | state = Win }, Cmd.none )

                    Err reason ->
                        ( { model | state = Error (reason) }, Cmd.none )

            _ ->
                ( model, Cmd.none )


type alias GitHubSearchResultItem =
    { name : String
    , url : String
    }


type alias GitHubSearchResult =
    { totalCount : Int, items : List GitHubSearchResultItem }


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
view { query, state } =
    div
        [ class "container" ]
        [ viewForkMe "https://github.com/halfzebra/drinking-game-for-web-devs"
        , case state of
            Starting ->
                div
                    [ class "fade-in" ]
                    [ div [ style [ ( "max-height", "250px" ), ( "overflow", "hidden" ) ] ] [ tweet ]
                    , button [ onClick StartGame, class "button" ] [ text "Start" ]
                    ]

            Playing ->
                div
                    [ class "fade-in" ]
                    [ input
                        [ onInput UpdateSearchQuery
                        , onKeyDown InputKeyDown
                        , value query
                        , class "search-input"
                        , id "search-input"
                        , placeholder <| String.toUpper "Search the noun"
                        ]
                        []
                    , button [ onClick Send, class "button" ] [ text "Search" ]
                    ]

            Loading ->
                div [] [ loadingIcon ]

            Win ->
                div
                    [ class "fade-in" ]
                    [ h2 [] [ text "You have won the game!" ]
                    , button [ onClick StartGame, class "button" ] [ text "Try again" ]
                    ]

            Lose ->
                div
                    [ class "fade-in" ]
                    [ h2 [] [ text "You have lost the game" ]
                    , button [ onClick StartGame, class "button" ] [ text "Try again" ]
                    ]

            Error msg ->
                div
                    []
                    [ text <| toString msg
                    , button [ onClick StartGame, class "button" ] [ text "Try again" ]
                    ]
        ]


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.Decode.map tagger keyCode)


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
        , script
            [ async True
            , src "//platform.twitter.com/widgets.js"
            , charset "utf-8"
            ]
            []
        ]


viewForkMe : String -> Html Msg
viewForkMe url =
    a
        [ attribute "aria-label" "View source on Github"
        , class "github-corner"
        , href url
        ]
        [ forkMeIcon ]
