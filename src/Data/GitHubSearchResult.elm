module Data.GitHubSearchResult exposing (..)

import Json.Decode exposing (Decoder)


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
