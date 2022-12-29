{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}

module Core where

import Data.Word

import qualified Control.Foldl as L
import Data.Vinyl.Curry (runcurryX)
import Frames

tableTypes "Row" "noahs-customers.csv"

loadRows :: IO (Frame Row)
loadRows = inCoreAoS (readTable "noahs-customers.csv")
