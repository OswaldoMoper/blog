{-# LANGUAGE OverloadedStrings #-}

-- | Content loading for the static-site generator: parse a Markdown file with
-- an /optional/ YAML front-matter block and resolve its metadata, deriving
-- sensible defaults from the file name when fields are missing.
module Content
  ( Doc (..)
  , DocMeta (..)
  , parseDoc
  , renderMarkdown
  , defaultDescription
  ) where

import           CMarkGFM           (commonmarkToHtml, optUnsafe)
import           Data.Aeson         (FromJSON (..), withObject, (.:?))
import           Data.Char          (isDigit, toUpper)
import           Data.Maybe         (fromMaybe)
import           Data.Text          (Text)
import qualified Data.Text          as T
import           Data.Text.Encoding (encodeUtf8)
import qualified Data.Yaml          as Yaml
import           Lucid              (Html, toHtmlRaw)
import           System.FilePath    (takeBaseName)

-- | Site-wide default meta description, shared by the home page and any content
-- page that doesn't set its own @description@.
defaultDescription :: Text
defaultDescription =
  "Oswaldo Moper — Haskell and Nix engineer. Reproducible, functional infrastructure, deep refactoring and system design."

-- | Raw, fully-optional front-matter. Every field may be omitted (or the whole
-- @---@ block left out entirely).
data FrontMatter = FrontMatter
  { fmTitle       :: Maybe Text
  , fmDescription :: Maybe Text
  , fmSlug        :: Maybe Text
  , fmInNav       :: Maybe Bool
  }

emptyFrontMatter :: FrontMatter
emptyFrontMatter = FrontMatter Nothing Nothing Nothing Nothing

instance FromJSON FrontMatter where
  parseJSON = withObject "FrontMatter" $ \o ->
    FrontMatter
      <$> o .:? "title"
      <*> o .:? "description"
      <*> o .:? "slug"
      <*> o .:? "inNav"

-- | Resolved metadata for a content page (defaults already applied).
data DocMeta = DocMeta
  { dmTitle       :: Text        -- ^ <title> + breadcrumb (front-matter or filename)
  , dmDescription :: Text        -- ^ meta description (front-matter or 'defaultDescription')
  , dmSlug        :: Text        -- ^ output path segment, e.g. "about" -> /about/
  , dmNavLabel    :: Text        -- ^ navbar label — always derived from the filename
  , dmInNav       :: Bool        -- ^ include in the navbar (default True)
  , dmOrder       :: Maybe Int   -- ^ numeric filename prefix, parsed as an Int
  }

-- | A parsed content document: its metadata and the raw Markdown body.
data Doc = Doc
  { docMeta   :: DocMeta
  , docBodyMd :: Text
  }

-- | Parse a content file. The YAML front-matter block is optional; when absent
-- the whole file is the Markdown body and all metadata comes from the filename.
--
-- > ---
-- > title: "Work with me"   # optional
-- > description: "…"        # optional
-- > slug: about             # optional (defaults to the filename)
-- > inNav: false            # optional (defaults to true)
-- > ---
-- > # markdown body…
parseDoc :: FilePath -> Text -> Either String Doc
parseDoc path input =
  case T.lines input of
    (l0 : rest)
      | T.strip l0 == "---" ->
          let (yamlLines, afterClose) =
                break (\l -> T.strip l == "---") rest
          in case afterClose of
               []                   -> Left "front-matter: missing closing '---'"
               (_close : bodyLines) ->
                 case Yaml.decodeEither' (encodeUtf8 (T.unlines yamlLines)) of
                   Left err -> Left ("front-matter YAML error: " <> show err)
                   Right fm -> Right (Doc (resolveMeta path fm) (T.unlines bodyLines))
    -- No leading '---': no front-matter, the whole file is the body.
    _ -> Right (Doc (resolveMeta path emptyFrontMatter) input)

-- | Fill in defaults from the filename for any field the front-matter omits.
resolveMeta :: FilePath -> FrontMatter -> DocMeta
resolveMeta path fm =
  DocMeta
    { dmTitle       = fromMaybe defLabel (fmTitle fm)
    , dmDescription = fromMaybe defaultDescription (fmDescription fm)
    , dmSlug        = fromMaybe defSlug (fmSlug fm)
    , dmNavLabel    = defLabel                 -- navbar label is always filename-derived
    , dmInNav       = fromMaybe True (fmInNav fm)
    , dmOrder       = parseNumPrefix base
    }
  where
    base     = takeBaseName path     -- "01-getting-started.md" -> "01-getting-started"
    stripped = dropNumPrefix base     -- "getting-started"
    defLabel = humanize stripped      -- "Getting Started"
    defSlug  = T.toLower (T.pack stripped)

-- | Parse a leading numeric prefix (digits followed by @-@/@_@) as an 'Int'.
-- Parsed as a number so @11-@ sorts after @9-@ without zero-padding.
parseNumPrefix :: String -> Maybe Int
parseNumPrefix s =
  case span isDigit s of
    (ds@(_ : _), sep : _) | sep == '-' || sep == '_' -> Just (read ds)
    _                                                 -> Nothing

-- | Drop a leading @NN-@ / @NN_@ numeric prefix, if present.
dropNumPrefix :: String -> String
dropNumPrefix s =
  case span isDigit s of
    (_ : _, sep : rest) | sep == '-' || sep == '_' -> rest
    _                                              -> s

-- | Turn a slug-ish name into a human label: split on @-@/@_@, capitalise words.
humanize :: String -> Text
humanize =
  T.unwords . map capitalise . filter (not . T.null)
            . T.split (\c -> c == '-' || c == '_') . T.pack
  where
    capitalise w = case T.uncons w of
      Just (c, rest) -> T.cons (toUpper c) rest
      Nothing        -> w

-- | Render trusted GitHub-flavored Markdown to HTML. 'optUnsafe' is enabled so
-- inline HTML (e.g. a Bootstrap @btn@ CTA) in our own content passes through.
renderMarkdown :: Text -> Html ()
renderMarkdown = toHtmlRaw . commonmarkToHtml [optUnsafe] []
