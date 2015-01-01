{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}

--
-- Copyright © 2013-2014 Anchor Systems, Pty Ltd and Others
--
-- The code in this file, and the program it is a part of, is
-- made available to you by its authors as open source software:
-- you can redistribute it and/or modify it under the terms of
-- the 3-clause BSD licence.
--

-- | Description: Define and operate on data sources.
--
-- /Synchronise/ interacts with external systems and propagates changes to
-- duplicated data between them; these external systems are 'DataSource's.
module Synchronise.DataSource (
    DataSource(..),
    Command,
    DSMonad,
    runDSMonad,
    -- * Operations
    get,
    set,
    delete,
) where

import Control.Applicative
import Control.Monad
import Control.Monad.Error.Class
import Control.Monad.IO.Class
import Control.Monad.Trans.Except
import Data.String
import Data.Text (Text)
import qualified Data.Text as T
import System.IO
import System.Process

import Synchronise.Document
import Synchronise.Identifier

-- | Command template.
newtype Command = Command { unCommand :: Text }
  deriving (Eq, Show, Ord)

instance IsString Command where
    fromString = Command . T.pack

-- | Record describing an external data source and how we interact with it.
data DataSource = DataSource
    { entityName    :: EntityName -- ^ Unique name for entity.
    , sourceName    :: SourceName -- ^ Unique name for this data source.
    , commandCreate :: Command    -- ^ Command template: create object.
    , commandRead   :: Command    -- ^ Command template: read object.
    , commandUpdate :: Command    -- ^ Command template: update object.
    , commandDelete :: Command    -- ^ Command template: delete object.
    }
  deriving (Eq, Show)

instance Synchronisable DataSource where
    getEntityName = entityName
    getSourceName = sourceName

newtype DSMonad a = DSMonad { unDSMonad :: ExceptT Text IO a }
  deriving (Applicative, Functor, Monad, MonadIO, MonadError Text)

runDSMonad :: DSMonad a -> IO (Either Text a)
runDSMonad = runExceptT . unDSMonad

-- | Prepare a 'Command' by interpolating
prepareCommand
    :: DataSource
    -> Maybe ForeignKey
    -> Command
    -> String
prepareCommand _ds fk cmd =
    case fk of
        Nothing -> T.unpack . unCommand $ cmd
        Just _fk -> T.unpack . unCommand $ cmd

-- | Check that a 'DataSource' and a 'ForeignKey' are compatible, otherwise
-- raise an error in the monad.
checkCompatibility
    :: (Synchronisable a, Synchronisable b)
    => a
    -> b
    -> DSMonad ()
checkCompatibility a b =
    unless (compatibleSource a b) $ throwError "Incompatible data sources!"

-- | Access a 'DataSource' and retrieve the 'Document' identified, in that source,
-- by the given 'ForeignKey'.
--
-- It is an error if the 'DataSource' and 'ForeignKey' supplied do not agree on
-- the entity and source names.
get
    :: DataSource
    -> ForeignKey
    -> DSMonad Document
get src fk = do
    -- 1. Check source and key are compatible.
    checkCompatibility src fk
    -- 2. Spawn process.
    let cmd = prepareCommand src (Just fk) . commandRead $ src
    let process = (shell cmd) { std_out = CreatePipe }
    (Nothing, Just hout, Nothing, hproc) <- liftIO $ createProcess process
    -- 3. Read output.
    -- 4. Check return code, raising error if required.
    exit <- liftIO $ waitForProcess hproc
    liftIO $ print exit
    -- 5. Close handles.
    liftIO $ hClose hout
    -- 6. Parse input and return value.
    error "DataSource.get is not implemented"

-- | Access a 'DataSource' and save the 'Document' under the specified
-- 'ForeignKey', returning the 'ForeignKey' to use for the updated document in
-- future.
--
-- If no 'ForeignKey' is supplied, this is, a create operation.
--
-- It is an error if the 'DataSource' and 'ForeignKey' supplied do not agree on
-- the entity and source names.
set
    :: DataSource
    -> Maybe ForeignKey -- ^ Key to update.
    -> Document
    -> DSMonad ForeignKey -- ^ New (or old) key for this document.
set _ _ _ =
    -- 1. Check source and key are compatible.
    -- 2. Spawn process.
    -- 3. Write input.
    -- 4. Read output.
    -- 5. Check return code, raising error if required.
    -- 6. Close handles.
    -- 7. Parse input and return value.
    error "DataSource.set is not implemented"

-- | Access a 'DataSource' and delete the 'Document' identified in that source
-- by the given 'ForeignKey'.
--
-- It is an error if the 'DataSource' and 'ForeignKey' do not agree on the
-- entity and source names.
delete
    :: DataSource
    -> ForeignKey
    -> IO ()
delete _ _ =
    -- 1. Check source and key are compatible.
    -- 2. Spawn process.
    -- 3. Read output
    -- 4. Check return code, raising error if required.
    -- 5. Close handles.
    -- 6. Parse output and return value.
    error "DataSource.delete is not implemented"
