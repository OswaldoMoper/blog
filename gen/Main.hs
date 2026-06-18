{-# LANGUAGE OverloadedStrings #-}

-- | Static-site generator. Renders the blog's Lucid templates to disk so the
-- result can be served by GitHub Pages. It reuses the pure templates from the
-- @blog@ library and never starts a Warp server.
module Main (main) where

import           Control.Monad               (forM, forM_)
import qualified Data.ByteString.Lazy        as BL
import           Data.List                   (sortOn)
import           Data.Maybe                  (fromMaybe)
import           Data.Text                   (Text)
import qualified Data.Text                   as T
import qualified Data.Text.IO                as TIO
import           GHC.IO.Encoding             (setLocaleEncoding, utf8)
import           Lucid
import           System.Directory            (copyFile,
                                              createDirectoryIfMissing,
                                              doesDirectoryExist, listDirectory)
import           System.Environment          (lookupEnv)
import           System.Exit                 (die)
import           System.FilePath             (takeDirectory, takeExtension,
                                              (</>))

import           Content
import           LucidTemplates.HomeTemplate (homepageTemplate)
import qualified Paths_blog                  as Paths
import           StaticGen.StaticLayout

data SiteConfig = SiteConfig
  { scOutDir    :: FilePath
  , scDomain    :: Text
  , scCopyright :: Text
  , scNav       :: [NavItem]
  }

-- | Stylesheet order mirrors the live server: bootstrap first (loaded via
-- @addStylesheetRemote@ in Foundation), then the site/layout CSS that the
-- server concatenates at runtime.
siteCss :: [Text]
siteCss =
  [ "/static/css/bootstrap.css"
  , "/static/css/default-layout.css"
  , "/static/css/homepage.css"
  ]

main :: IO ()
main = do
  -- Nix's build sandbox has no UTF-8 locale, so force it for reading content
  -- (em dashes, accents) and writing output regardless of the ambient LANG.
  setLocaleEncoding utf8
  -- $SITE_OUT lets the Nix derivation target $out directly; defaults to ./_site
  -- for local iteration via `nix run .#gen`.
  outDir <- fromMaybe "_site" <$> lookupEnv "SITE_OUT"

  -- Load content first so the navbar can be built from it.
  docs <- loadContentPages
  let cfg = SiteConfig
        { scOutDir    = outDir
        , scDomain    = "OswaldoMoper.com"
        , scCopyright = "© 2025-2026 Oswaldo Moper."
        , scNav       = buildNav docs
        }
  createDirectoryIfMissing True outDir

  writeHtmlFile (outDir </> "index.html") (renderHome cfg)

  forM_ docs $ \doc -> do
    let slug = T.unpack (dmSlug (docMeta doc))
    writeHtmlFile (outDir </> slug </> "index.html") (renderPage cfg doc)

  forM_ ["bootstrap.css", "default-layout.css", "homepage.css"] $ \name -> do
    src <- Paths.getDataFileName ("static/css" </> name)
    copyInto src (outDir </> "static" </> "css" </> name)

  TIO.writeFile (outDir </> "CNAME") (scDomain cfg <> "\n")
  Paths.getDataFileName "config/robots.txt"  >>= \s -> copyInto s (outDir </> "robots.txt")
  Paths.getDataFileName "config/favicon.ico" >>= \s -> copyInto s (outDir </> "favicon.ico")

  writeHtmlFile (outDir </> "404.html") (render404 cfg)

  putStrLn ("Static site written to " <> outDir)

-- | Load every @*.md@ under the bundled @content/pages@ directory.
loadContentPages :: IO [Doc]
loadContentPages = do
  dir    <- Paths.getDataFileName "content/pages"
  exists <- doesDirectoryExist dir
  if not exists
    then pure []
    else do
      names <- listDirectory dir
      let mds = filter ((== ".md") . takeExtension) names
      forM mds $ \name -> do
        raw <- TIO.readFile (dir </> name)
        case parseDoc name raw of
          Left err  -> die ("Failed to parse " <> name <> ": " <> err)
          Right doc -> pure doc

-- | Build the navbar from three sources under a single ordering: Home (pinned
-- first), content pages (by numeric filename prefix), and external/off-site
-- links (NixTalk), which sort last. Pages without a numeric prefix fall after
-- the numbered ones; external links use 'maxBound' so they always trail.
buildNav :: [Doc] -> [NavItem]
buildNav docs =
  NavItem "Home" "/" : map snd (sortOn fst (pageEntries ++ externalNav))
  where
    pageEntries =
      [ (fromMaybe defaultOrder (dmOrder m), NavItem (dmNavLabel m) ("/" <> dmSlug m <> "/"))
      | doc <- docs
      , let m = docMeta doc
      , dmInNav m
      ]
    defaultOrder = 1000 :: Int
    -- External / off-site links, ordered after every content page.
    externalNav =
      [ (maxBound, NavItem "NixTalk" "https://nixtalk.oswaldomoper.com") ]

renderHome :: SiteConfig -> Html ()
renderHome cfg = staticLayout StaticPage
  { spTitle       = "Oswaldo Moper - Reproducible and functional infrastructure"
  , spDescription = defaultDescription
  , spCssHrefs    = siteCss
  , spNav         = scNav cfg
  , spActiveHref  = Just "/"
  , spIsHome      = True
  , spBody        = homepageTemplate
  , spCopyright   = scCopyright cfg
  }

renderPage :: SiteConfig -> Doc -> Html ()
renderPage cfg doc = staticLayout StaticPage
  { spTitle       = dmTitle meta
  , spDescription = dmDescription meta
  , spCssHrefs    = siteCss
  , spNav         = scNav cfg
  , spActiveHref  = Just ("/" <> dmSlug meta <> "/")
  , spIsHome      = False
  , spBody        = renderMarkdown (docBodyMd doc)
  , spCopyright   = scCopyright cfg
  }
  where meta = docMeta doc

render404 :: SiteConfig -> Html ()
render404 cfg = staticLayout StaticPage
  { spTitle       = "Page not found"
  , spDescription = "The page you were looking for does not exist."
  , spCssHrefs    = siteCss
  , spNav         = scNav cfg
  , spActiveHref  = Nothing
  , spIsHome      = False
  , spBody        = do
      h1_ "404 — Page not found"
      p_ $ do
        "The page you were looking for does not exist. "
        a_ [ href_ "/" ] "Go back home"
        "."
  , spCopyright   = scCopyright cfg
  }

writeHtmlFile :: FilePath -> Html () -> IO ()
writeHtmlFile dest html = do
  createDirectoryIfMissing True (takeDirectory dest)
  BL.writeFile dest (renderBS html)

copyInto :: FilePath -> FilePath -> IO ()
copyInto src dest = do
  createDirectoryIfMissing True (takeDirectory dest)
  copyFile src dest
