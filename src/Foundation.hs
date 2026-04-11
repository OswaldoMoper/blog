{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE TypeFamilies          #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Foundation where

import           Control.Monad.Logger           (LogSource)
import           Import.NoFoundation
import           LucidTemplates.DefaultTemplate
import           Text.Jasmine                   (minifym)
import           Yesod.Core.Types               (Logger)
import qualified Yesod.Core.Unsafe              as Unsafe
import           Yesod.Default.Util             (addStaticContentExternal)

instance Yesod App where
  approot :: Approot App
  approot = ApprootRequest $ \app req ->
    case appRoot $ appSettings app of
      Nothing   -> getApprootText guessApproot app req
      Just root -> root

  makeSessionBackend :: App -> IO (Maybe SessionBackend)
  makeSessionBackend _ = Just <$> defaultClientSessionBackend
      120    -- timeout in minutes
      "config/client_session_key.aes"

  yesodMiddleware :: ToTypedContent res => Handler res -> Handler res
  yesodMiddleware = defaultYesodMiddleware

  isAuthorized
    :: Route App  -- ^ The route the user is visiting.
    -> Bool       -- ^ Whether or not this is a "write" request.
    -> Handler AuthResult
  isAuthorized FaviconR _ = return Authorized
  isAuthorized RobotsR _  = return Authorized
  isAuthorized _ _        = return Authorized

  addStaticContent
    :: Text  -- ^ The file extension
    -> Text -- ^ The MIME content type
    -> LByteString -- ^ The contents of the file
    -> Handler (Maybe (Either Text (Route App, [(Text, Text)])))
  addStaticContent ext mime content = do
    master <- getYesod
    let staticDir = appStaticDir $ appSettings master
    addStaticContentExternal
      minifym
      genFileName
      staticDir
      (StaticR . flip StaticRoute [])
      ext
      mime
      content
    where
      -- Generate a unique filename based on the content itself
      genFileName lbs = "autogen-" ++ base64md5 lbs

  shouldLogIO :: App -> LogSource -> LogLevel -> IO Bool
  shouldLogIO app _source level =
    return $
    appShouldLogAll (appSettings app)
      || level == LevelWarn
      || level == LevelError

  makeLogger :: App -> IO Logger
  makeLogger = return . appLogger

-- Define breadcrumbs.
instance YesodBreadcrumbs App where
  breadcrumb
    :: Route App  -- ^ The route the user is visiting currently.
    -> Handler (Text, Maybe (Route App))
  breadcrumb HomeR = return ("Home", Nothing)
  breadcrumb  _    = return ("home", Nothing)

-- This instance is required to use forms. You can modify renderMessage to
-- achieve customized and internationalized form validation messages.
instance RenderMessage App FormMessage where
  renderMessage :: App -> [Lang] -> FormMessage -> Text
  renderMessage _ _ = defaultFormMessage

-- Useful when writing code that is re-usable outside of the Handler context.
-- An example is background jobs that send email.
-- This can also be useful for writing code that works across multiple Yesod applications.
instance HasHttpManager App where
  getHttpManager :: App -> Manager
  getHttpManager = appHttpManager

unsafeHandler :: App -> Handler a -> IO a
unsafeHandler = Unsafe.fakeHandlerGetLogger appLogger

customLayout :: Widget -> Handler LucidHtml
customLayout widget = do
  master        <- getYesod
  mmsg          <- getMessage
  mcurrentRoute <- getCurrentRoute
  (_, parents)  <- breadcrumbs
  let menuItems =
          [ NavbarLeft $ MenuItem
            { menuItemLabel = "Home"
            , menuItemRoute = HomeR
            , menuItemAccessCallback = True
            }
          ]
      navbarLeftMenuItems = [x | NavbarLeft x <- menuItems]
      navbarRightMenuItems = [x | NavbarRight x <- menuItems]
      navbarLeftFilteredMenuItems = [x | x <- navbarLeftMenuItems, menuItemAccessCallback x]
      navbarRightFilteredMenuItems = [x | x <- navbarRightMenuItems, menuItemAccessCallback x]
      copyright = appCopyright $ appSettings master
      layoutC = LayoutContext
        { lcCurrentRoute = mcurrentRoute
        , lcMenuLeft     = navbarLeftFilteredMenuItems
        , lcMenuRight    = navbarRightFilteredMenuItems
        , lcBreadcrumbs  = parents
        , lcFlashMessage = fmap blazeToLucid mmsg
        , lcCopyright    = copyright
        , lcAnalytics    = appAnalytics $ appSettings master
        }
      fullWidget = do
        addStylesheetRemote "/static/css/bootstrap.css"
        widget
  pc <- widgetToPageContent fullWidget
  withUrlRenderer $ \render ->
    defaultLayoutWrapper render pc layoutC
