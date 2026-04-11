{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE NoImplicitPrelude    #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE RankNTypes           #-}
{-# LANGUAGE ScopedTypeVariables  #-}

module LucidTemplates.DefaultTemplate where

import qualified Data.CaseInsensitive          as CI
import qualified Data.Text.Encoding            as TE
import           Import.NoFoundation           as IN
import           Text.Blaze.Html.Renderer.Text (renderHtml)

type Render route = route -> [(Text, Text)] -> Text

routeToText :: Route App -> Text
routeToText = ("/" <>) . intercalate "/" . fst . renderRoute

defaultLayoutWrapper :: Render (Route App) -> PageContent (Route App) -> LayoutContext (Route App) -> Html ()
defaultLayoutWrapper render pc lc = do
  doctype_
  html_ [ class_ "no-js", lang_ "en" ] $ do
    head_ $ do
      meta_ [ charset_ "utf-8" ]
      title_ $ toHtml $ renderHtml $ pageTitle pc
      meta_ [ name_ "description", content_ "YesodNix - the best framework" ]
      meta_ [ name_ "author", content_ "Oscar Oswaldo Moya Pérez" ]
      meta_ [ name_ "viewport", content_ "width=device-width, initial-scale=1" ]
      IN.blazeToLucid $ pageHead pc render
      toHtmlRaw ("<!--[if lt IE 9]><script src=\"http://html5shiv.googlecode.com/svn/trunk/html5.js\"></script><![endif]-->" :: Text)
      script_ [ type_ "text/javascript"
              , src_ "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.4/jquery.js" ] ("" :: Text)
      script_ [ src_ "https://cdnjs.cloudflare.com/ajax/libs/js-cookie/2.0.3/js.cookie.min.js" ] ("" :: Text)
      toHtmlRaw ("<!-- Bootstrap-3.3.7 compiled and minified JavaScript -->" :: Text)
      script_ [ src_ "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
              , integrity_ "sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
              , crossorigin_ "anonymous" ] ("" :: Text)
      csrfScript (TE.decodeUtf8 $ CI.foldedCase defaultCsrfHeaderName)
                 (TE.decodeUtf8 defaultCsrfCookieName)
      script_ "document.documentElement.className = document.documentElement.className.replace(/\\bno-js\\b/, 'js');"
    body_ $ do
      defaultNavBar render (lcCurrentRoute lc) (lcMenuLeft lc) (lcMenuRight lc)
      defaultPageContent (lcCurrentRoute lc) (lcBreadcrumbs lc)
                         (toStrict . renderHtml $ pageTitle pc)
                         (lcFlashMessage lc)
                         (blazeToLucid $ pageBody pc render)
      defaultFooter (lcCopyright lc)
      -- forM_ (lcAnalytics lc) $ \analytics -> do
      --   script_ $ toHtmlRaw $
      --     "if(!window.location.href.match(/localhost/)){\n" <>
      --     "(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n" <>
      --     "(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n" <>
      --     "m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n" <>
      --     "})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');\n" <>
      --     "ga('create', '" <> analytics <> "', 'auto');\n" <>
      --     "ga('send', 'pageview');\n}"

csrfScript :: Text -> Text -> Html ()
csrfScript headerName cookieName =
  let js :: Html ()
      js = toHtmlRaw (
        "var csrfHeaderName = \"" <> headerName <> "\";\n" <>
        "var csrfCookieName = \"" <> cookieName <> "\";\n" <>
        "var csrfToken = Cookies.get(csrfCookieName);\n" <>
        "if (csrfToken) {\n" <>
        "  $.ajaxPrefilter(function(options, originalOptions, jqXHR) {\n" <>
        "    if (!options.crossDomain) {\n" <>
        "      jqXHR.setRequestHeader(csrfHeaderName, csrfToken);\n" <>
        "    }\n" <>
        "  });\n" <>
        "}")
  in script_ [] js

defaultNavBar :: Render (Route App)
              -> Maybe (Route App)
              -> [MenuItem]
              -> [MenuItem]
              -> Html ()
defaultNavBar render mcurrentRoute leftItems rightItems = do
  nav_ [ class_ "navbar navbar-default navbar-static-top" ] $ do
    div_ [ class_ "container" ] $ do
      div_ [ class_ "navbar-header" ] $ do
        button_ [ type_ "button"
                , class_ "navbar-toggle collapsed"
                , data_ "toggle" "collapse"
                , data_ "target" "#navbar"
                , makeAttribute "aria-expanded" "false"
                , makeAttribute "aria-controls" "navbar" ] $ do
          span_  [ class_ "sr-only" ] "Toggle navigation"
          replicateM_ 3 $ span_ [ class_ "icon-bar" ] mempty
      div_ [id_ "navbar", class_ "collapse navbar-collapse"] $ do
        ul_ [class_ "nav navbar-nav"] $
          forM_ leftItems $ \(MenuItem label route _) ->
            li_ [class_ $ if Just route == mcurrentRoute
                          then "active"
                          else ""] $
              a_ [href_ $ render route [] ] (toHtml label)
        ul_ [class_ "nav navbar-nav navbar-right"] $
          forM_ rightItems $ \(MenuItem label route _) ->
            li_ [class_ $ if Just route == mcurrentRoute
                          then "active"
                          else ""] $
              a_ [href_ $ render route [] ] (toHtml label)

defaultPageContent :: Maybe (Route App)
                   -> [(Route App, Text)] -- ^ parents for breadcrumb
                   -> Text                -- ^ title
                   -> Maybe LucidHtml     -- ^ message to show (if any)
                   -> Html ()             -- ^ main widget content
                   -> Html ()
defaultPageContent mcurrentRoute parents title mmsg widget = do
  div_ [class_ "container"] $ do
    unless (Just HomeR == mcurrentRoute) $
      ul_ [class_ "breadcrumb"] $ do
        forM_ parents $ \(r, lbl) ->
          li_ $ a_ [href_ $ routeToText r] (toHtml lbl)
        li_ [class_ "active"] (toHtml title)

    forM_ mmsg $ \msg ->
      div_ [class_ "alert alert-info", id_ "message"] msg

  if Just HomeR == mcurrentRoute
  then widget
  else div_ [class_ "container"] $
         div_ [class_ "row"] $
           div_ [class_ "col-md-12"]
             widget

defaultFooter :: Text -> Html ()
defaultFooter copyright = footer_ [class_ "footer"] $
  div_ [class_ "container"] $
    p_ [class_ "text-muted"] (toHtml copyright)
