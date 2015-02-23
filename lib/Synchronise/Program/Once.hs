--
-- Copyright © 2014-2015 Anchor Systems, Pty Ltd and Others
--
-- The code in this file, and the program it is a part of, is
-- made available to you by its authors as open source software:
-- you can redistribute it and/or modify it under the terms of
-- the 3-clause BSD licence.
--

-- | Description: Run /Synchronise/ as a one-short command.
module Synchronise.Program.Once where

import Control.Monad.Error.Class
import Data.Aeson
import Data.Either
import Data.Monoid

import Synchronise.Configuration
import Synchronise.DataSource
import Synchronise.Document
import Synchronise.Identifier

-- | A request to be processed.
data Request
    = Create { commandKey :: ForeignKey }
    | Read   { commandKey :: ForeignKey }
    | Update { commandKey :: ForeignKey }
    | Delete { commandKey :: ForeignKey }
  deriving (Eq, Show)

-- | Run a single command.
synchroniseOnce
    :: Request
    -> Configuration
    -> IO ()
synchroniseOnce req cfg = do
    let rk = commandKey req
    ds <- either report return $ getDataSource cfg (fkEntity rk) (fkSource rk)

    case req of
        Create fk -> inputDocument fk >>= exec . createDocument ds
        Read   fk -> exec $ readDocument ds fk
        Update fk -> inputDocument rk >>= exec . updateDocument ds fk
        Delete fk -> exec $ deleteDocument ds fk
  where
    report e = do
        error $ e <> "\n" <> show cfg
    exec :: Show a => DSMonad a -> IO ()
    exec a = do
        res <- runDSMonad a
        case res of
            Left e -> error $ show e
            Right v -> print v

-- | Read JSON from standard input and produce a 'Document'.
inputDocument
    :: ForeignKey
    -> IO Document
inputDocument fk =
    let e = fkEntity fk
        s = fkSource fk
    in return $ Document e s Null
