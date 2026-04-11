{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE TypeFamilies          #-}

module Handler.Home where

import qualified Data.ByteString.Lazy           as L
import           Data.Foldable                  (for_)
import           Import
import           LucidTemplates.HomeTemplate

registerCssFiles :: [FilePath] -> Handler (Maybe (Route App))
registerCssFiles paths = do
  let allPaths = "static/css/default-layout.css" : paths
  contents <- mapM (liftIO . L.readFile) allPaths
  let combined = mconcat contents
  result <- addStaticContent "css" "text/css" combined
  pure $ case result of
    Just (Right (route, _)) -> Just route
    _                       -> Nothing

getHomeR :: Handler LucidHtml
getHomeR = do
    m_css   <- registerCssFiles [ "static/css/homepage.css" ]
    customLayout $ do
        setTitle "Oswaldo Moper - Reproducible and functional infrastructure"
        Data.Foldable.for_ m_css addStylesheet
        toWidget homepageTemplate
