{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module TestImport
    ( module TestImport
    , module X
    ) where

import           Application           (makeFoundation, makeLogWare)
import           ClassyPrelude         as X hiding (Handler)
import           Foundation            as X
import           Test.Hspec            as X
import           Yesod.Core.Unsafe     (fakeHandlerGetLogger)
import           Yesod.Default.Config2 (loadYamlSettings, useEnv)
import           Yesod.Test            as X

runHandler :: Handler a -> YesodExample App a
runHandler handler = do
    app <- getTestYesod
    fakeHandlerGetLogger appLogger app handler


withApp :: SpecWith (TestApp App) -> Spec
withApp = before $ do
    settings <- loadYamlSettings
        ["config/test-settings.yml", "config/settings.yml"]
        []
        useEnv
    foundation <- makeFoundation settings
    logWare <- liftIO $ makeLogWare foundation
    return (foundation, logWare)
