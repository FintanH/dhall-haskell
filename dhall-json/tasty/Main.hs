{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main where

import Dhall.JSON (Conversion(..))
import Test.Tasty (TestTree)

import qualified Control.Exception
import qualified Data.Aeson
import qualified Data.ByteString.Lazy
import qualified Data.Text
import qualified Data.Text.IO
import qualified Dhall.Import
import qualified Dhall.JSON
import qualified Dhall.Parser
import qualified Dhall.Yaml
import qualified Test.Tasty
import qualified Test.Tasty.HUnit

main :: IO ()
main = Test.Tasty.defaultMain testTree

testTree :: TestTree
testTree =
    Test.Tasty.testGroup "dhall-json"
        [ issue48
        , yamlQuotedStrings
        , yaml
        ]

issue48 :: TestTree
issue48 = Test.Tasty.HUnit.testCase "Issue #48" assertion
  where
    assertion = do
        let file = "./tasty/data/issue48.dhall"

        code <- Data.Text.IO.readFile file

        parsedExpression <- case Dhall.Parser.exprFromText file code of
            Left  exception        -> Control.Exception.throwIO exception
            Right parsedExpression -> return parsedExpression

        resolvedExpression <- Dhall.Import.load parsedExpression

        let mapKey     = "mapKey"
        let mapValue   = "mapValue"
        let conversion = Conversion {..}

        let convertedExpression =
                Dhall.JSON.convertToHomogeneousMaps conversion resolvedExpression

        actualValue <- case Dhall.JSON.dhallToJSON convertedExpression of
            Left  exception   -> Control.Exception.throwIO exception
            Right actualValue -> return actualValue

        bytes <- Data.ByteString.Lazy.readFile "./tasty/data/issue48.json"

        expectedValue <- case Data.Aeson.eitherDecode bytes of
            Left  string        -> fail string
            Right expectedValue -> return expectedValue

        let message =
                "Conversion to homogeneous maps did not generate the expected JSON output"

        Test.Tasty.HUnit.assertEqual message expectedValue actualValue

yamlQuotedStrings :: TestTree
yamlQuotedStrings = Test.Tasty.HUnit.testCase "Yaml: quoted string style" assertion
  where
    assertion = do
        let file = "./tasty/data/yaml.dhall"

        code <- Data.Text.IO.readFile file

        let options =
              Dhall.Yaml.defaultOptions { Dhall.Yaml.quoted = True }

        actualValue <-
          Dhall.Yaml.dhallToYaml options (Data.Text.pack file) code

        bytes <- Data.ByteString.Lazy.readFile "./tasty/data/quoted.yaml"

        let expectedValue = Data.ByteString.Lazy.toStrict bytes

        let message =
              "Conversion to quoted yaml did not generate the expected output"

        Test.Tasty.HUnit.assertEqual message expectedValue actualValue

yaml :: TestTree
yaml = Test.Tasty.HUnit.testCase "Yaml: normal string style" assertion
  where
    assertion = do
        let file = "./tasty/data/yaml.dhall"

        code <- Data.Text.IO.readFile file

        actualValue <-
          Dhall.Yaml.dhallToYaml Dhall.Yaml.defaultOptions (Data.Text.pack file) code

        bytes <- Data.ByteString.Lazy.readFile "./tasty/data/normal.yaml"

        let expectedValue = Data.ByteString.Lazy.toStrict bytes

        let message =
                "Conversion to normal yaml did not generate the expected output"

        Test.Tasty.HUnit.assertEqual message expectedValue actualValue
