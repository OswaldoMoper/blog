{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE ViewPatterns          #-}
{-# OPTIONS_GHC -fno-warn-orphans  #-}

module Types where

import           ClassyPrelude.Yesod    (Bool, Manager, Maybe (..), Text,
                                         mkYesodData, parseRoutesFile, (.))
import           Control.Monad.Identity
import           Lucid
import           Settings               (AppSettings)
import qualified Yesod.Core             as Y
import           Yesod.Core             (HasContentType (..),
                                         RenderRoute (..), Route,
                                         ToContent, ToTypedContent, ToWidget)
import           Yesod.Core.Types       (Logger)
import           Yesod.Static           (Static)
import qualified Text.Blaze.Html                as Blaze (preEscapedToHtml)

-- | Define routes
mkYesodData "App" $(parseRoutesFile "config/routes.yesodroutes")

-- | The foundation datatype for your application. This can be a good place to
-- keep settings and values requiring initialization before your application
-- starts running, such as database connections. Every handler will have
-- access to the data present here.
data App = App
    { appSettings    :: AppSettings
    , appStatic      :: Static -- ^ Settings for static file serving.
    , appHttpManager :: Manager
    , appLogger      :: Logger
    }

data MenuItem = MenuItem
    { menuItemLabel          :: Text
    , menuItemRoute          :: Route App
    , menuItemAccessCallback :: Bool
    }

data MenuTypes
    = NavbarLeft MenuItem
    | NavbarRight MenuItem

data LayoutContext route = LayoutContext
  { lcCurrentRoute :: Maybe (Route App)
  , lcMenuLeft     :: [MenuItem]
  , lcMenuRight    :: [MenuItem]
  , lcBreadcrumbs  :: [(Route App, Text)]
  , lcFlashMessage :: Maybe LucidHtml
  , lcCopyright    :: Text
  , lcAnalytics    :: Maybe Text
  }

-- | Lucid support for Yesod.

-- | Handler LucidHtml can be used for yesod handlers that use lucid
type LucidHtml = Html ()

instance ToTypedContent (Html ()) where
  toTypedContent m = Y.TypedContent (getContentType (Just m)) (Y.toContent m)

instance ToContent (Html ()) where
  toContent html = Y.ContentBuilder (runIdentity (execHtmlT html)) Nothing

instance HasContentType (Html ()) where
  getContentType _ = "text/html"

-- | A convenient instance to Lucid.
instance Y.Yesod site => ToWidget site LucidHtml where
  toWidget = Y.toWidget . Blaze.preEscapedToHtml . renderText
