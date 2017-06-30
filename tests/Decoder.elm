module Decoder exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import Json.Decode
import Data.GitHubSearchResult


suite : Test
suite =
    describe "Decoder gitHubSearchResult"
        [ test "gitHubSearchResultItemDecoder can decode a record with name and url"
            (\() ->
                let
                    input =
                        """
                        {
                            "name" : "Hello",
                            "url" : "http://some-url.com"
                        }
                        """

                    decodedOutput =
                        Json.Decode.decodeString
                            Data.GitHubSearchResult.gitHubSearchResultItemDecoder
                            input
                in
                    Expect.equal decodedOutput
                        (Ok
                            { name = "Hello"
                            , url = "http://some-url.com"
                            }
                        )
            )
        , test "gitHubSearchResultDecoder can decode an empty list of result items and total count of 0"
            (\() ->
                let
                    input =
                        """
                        {
                            "total_count" : 0,
                            "items" : []
                        }
                        """

                    decodedOutput =
                        Json.Decode.decodeString
                            Data.GitHubSearchResult.gitHubSearchResultDecoder
                            input
                in
                    Expect.equal decodedOutput
                        (Ok
                            { totalCount = 0
                            , items = []
                            }
                        )
            )
        ]
