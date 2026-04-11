{-# LANGUAGE CPP #-}
module Import.NoFoundation
    ( module Import
    , blazeToLucid
    ) where

import           ClassyPrelude.Yesod           as Import hiding (Html, for_,
                                                          toHtml)
import           Lucid                         as Import
import           Lucid.Base                    as Import
import           Settings                      as Import
import qualified Text.Blaze.Html               as Blaze (Html)
import           Text.Blaze.Html.Renderer.Text (renderHtml)
import           Types                         as Import
import           Yesod.Core.Types              as Import (loggerSet)
import           Yesod.Default.Config2         as Import

blazeToLucid :: Blaze.Html -> Html ()
blazeToLucid h = toHtmlRaw (renderHtml h)
