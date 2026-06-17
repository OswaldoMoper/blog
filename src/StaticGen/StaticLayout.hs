{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings    #-}

-- | A route-free, server-free layout used by the static-site generator.
--
-- It deliberately mirrors the HTML produced by
-- 'LucidTemplates.DefaultTemplate.defaultLayoutWrapper' (same Bootstrap-3
-- markup) but drops everything that only makes sense inside the live Yesod
-- server: the CSRF script, the @PageContent@-derived @pageHead@/@pageBody@,
-- and the hash-named stylesheet route produced by @addStaticContent@.
--
-- The genuinely pure helpers are shared with the live layout
-- ('LucidTemplates.HomeTemplate.homepageTemplate' and
-- 'LucidTemplates.DefaultTemplate.defaultFooter'); only the nav/content
-- helpers are reimplemented here against plain 'Text' hrefs so the generator
-- never has to build a @Route App@ or a @Render@ function.
module StaticGen.StaticLayout
  ( NavItem (..)
  , StaticPage (..)
  , staticLayout
  , staticNavBar
  , staticPageContent
  ) where

import           Control.Monad                  (forM_, replicateM_, unless)
import           Data.Text                      (Text)
import           Lucid
import           Lucid.Base                     (makeAttribute)

import           LucidTemplates.DefaultTemplate (defaultFooter)

-- | A navbar entry. Route-free: just a label and an absolute href.
data NavItem = NavItem
  { niLabel :: Text
  , niHref  :: Text
  }

-- | Everything the static layout needs to render a full document. No
-- @Route App@, no @PageContent@, no CSRF.
data StaticPage = StaticPage
  { spTitle       :: Text         -- ^ <title> and breadcrumb label
  , spDescription :: Text         -- ^ real meta description (no placeholder)
  , spCssHrefs    :: [Text]       -- ^ plain stylesheet hrefs, in order
  , spNav         :: [NavItem]    -- ^ navbar items
  , spActiveHref  :: Maybe Text   -- ^ which nav href gets the "active" class
  , spIsHome      :: Bool         -- ^ home gets no breadcrumb / no container wrap
  , spBody        :: Html ()      -- ^ already-rendered page content
  , spCopyright   :: Text         -- ^ footer copyright
  }

-- | Render a complete @<!doctype html>@ document.
staticLayout :: StaticPage -> Html ()
staticLayout sp = do
  doctype_
  html_ [ class_ "no-js", lang_ "en" ] $ do
    head_ $ do
      meta_ [ charset_ "utf-8" ]
      title_ (toHtml (spTitle sp))
      meta_ [ name_ "description", content_ (spDescription sp) ]
      meta_ [ name_ "author", content_ "Oscar Oswaldo Moya Pérez" ]
      meta_ [ name_ "viewport", content_ "width=device-width, initial-scale=1" ]
      forM_ (spCssHrefs sp) $ \href ->
        link_ [ rel_ "stylesheet", href_ href ]
      script_ [ type_ "text/javascript"
              , src_ "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.4/jquery.js" ] ("" :: Text)
      script_ [ src_ "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
              , integrity_ "sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
              , crossorigin_ "anonymous" ] ("" :: Text)
      script_ "document.documentElement.className = document.documentElement.className.replace(/\\bno-js\\b/, 'js');"
    body_ $ do
      staticNavBar (spNav sp) (spActiveHref sp)
      staticPageContent (spIsHome sp) (spTitle sp) (spBody sp)
      defaultFooter (spCopyright sp)

-- | Bootstrap-3 navbar. Mirrors 'LucidTemplates.DefaultTemplate.defaultNavBar'
-- but matches the active item by href instead of @Route App@.
staticNavBar :: [NavItem] -> Maybe Text -> Html ()
staticNavBar items mactive =
  nav_ [ class_ "navbar navbar-default navbar-static-top" ] $
    div_ [ class_ "container" ] $ do
      div_ [ class_ "navbar-header" ] $
        button_ [ type_ "button"
                , class_ "navbar-toggle collapsed"
                , data_ "toggle" "collapse"
                , data_ "target" "#navbar"
                , makeAttribute "aria-expanded" "false"
                , makeAttribute "aria-controls" "navbar" ] $ do
          span_ [ class_ "sr-only" ] "Toggle navigation"
          replicateM_ 3 $ span_ [ class_ "icon-bar" ] mempty
      div_ [ id_ "navbar", class_ "collapse navbar-collapse" ] $
        ul_ [ class_ "nav navbar-nav" ] $
          forM_ items $ \(NavItem label href) ->
            li_ [ class_ (if Just href == mactive then "active" else "") ] $
              a_ [ href_ href ] (toHtml label)

-- | Page body wrapper. Mirrors
-- 'LucidTemplates.DefaultTemplate.defaultPageContent': the home page renders
-- its widget full-bleed, everything else gets a breadcrumb + container/row.
staticPageContent :: Bool -> Text -> Html () -> Html ()
staticPageContent isHome title widget = do
  unless isHome $
    div_ [ class_ "container" ] $
      ul_ [ class_ "breadcrumb" ] $ do
        li_ $ a_ [ href_ "/" ] "Home"
        li_ [ class_ "active" ] (toHtml title)
  if isHome
    then widget
    else div_ [ class_ "container" ] $
           div_ [ class_ "row" ] $
             div_ [ class_ "col-md-12" ] widget
