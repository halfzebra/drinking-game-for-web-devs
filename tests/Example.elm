module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import Test exposing (..)
import Json.Decode
import Data.GitHubSearchResult


suite : Test
suite =
    describe "Decoder"
        [ test "hello"
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
        ]
