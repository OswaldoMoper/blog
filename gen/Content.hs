{-# LANGUAGE OverloadedStrings #-}

module Content
  ( Doc (..)
  , DocMeta (..)
  , parseDoc
  , renderMarkdown
  ) where

import           CMarkGFM           (commonmarkToHtml, optUnsafe)
import           Data.Aeson         (FromJSON (..), withObject, (.!=), (.:),
                                     (.:?))
import           Data.Text          (Text)
import qualified Data.Text          as T
import           Data.Text.Encoding (encodeUtf8)
import qualified Data.Yaml          as Yaml
import           Lucid              (Html, toHtmlRaw)

-- | Front-matter metadata for a content page.
data DocMeta = DocMeta
  { dmTitle       :: Text
  , dmDescription :: Text
  , dmSlug        :: Text  -- ^ output path segment, e.g. "about" -> /about/
  }

instance FromJSON DocMeta where
  parseJSON = withObject "DocMeta" $ \o ->
    DocMeta
      <$> o .:  "title"
      <*> o .:? "description" .!= ""
      <*> o .:  "slug"

-- | A parsed content document: its metadata and the raw markdown body.
data Doc = Doc
  { docMeta   :: DocMeta
  , docBodyMd :: Text
  }

-- | Split a leading @---@ YAML front-matter block from the markdown body.
--
-- Expected shape:
--
-- > ---
-- > title: "Work with me"
-- > slug: about
-- > ---
-- > # markdown body...
parseDoc :: Text -> Either String Doc
parseDoc input =
  case T.lines input of
    (l0 : rest)
      | T.strip l0 == "---" ->
          let (yamlLines, afterClose) =
                break (\l -> T.strip l == "---") rest
          in case afterClose of
               []                  -> Left "front-matter: missing closing '---'"
               (_close : bodyLines) ->
                 case Yaml.decodeEither' (encodeUtf8 (T.unlines yamlLines)) of
                   Left err   -> Left ("front-matter YAML error: " <> show err)
                   Right meta -> Right (Doc meta (T.unlines bodyLines))
    _ -> Left "front-matter: file must start with a '---' line"

renderMarkdown :: Text -> Html ()
renderMarkdown = toHtmlRaw . commonmarkToHtml [optUnsafe] []
