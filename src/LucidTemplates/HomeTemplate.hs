{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE NoImplicitPrelude    #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE ScopedTypeVariables  #-}

module LucidTemplates.HomeTemplate where

import           Import     hiding (Html, for_, toHtml, (==.))
import           Lucid

homepageTemplate :: Html ()
homepageTemplate = do
  div_ [ class_ "masthead" ] $ do
    div_ [ class_ "container" ] $ do
      div_ [ class_ "row" ] $ do
        p_ [] " "
        h1_ [class_ "header" ]
          "Oswaldo Moper"
        p_ [] " "
        h2_ [  ]
          "Haskell and Nix enthusiast, speaker, and open source contributor"
        p_ [ style_ "margin:80px" ] " "
        a_ [ href_ "https://www.linkedin.com/in/oswaldomoper/"
           , class_ "btn btn-info btn-lg"]
          "Check my Linkedin profile"
        p_ [] " "
        a_ [ href_ "https://github.com/OswaldoMoper?tab=repositories"
           , class_ "btn btn-info btn-lg"]
          "Check my projects"
        p_ [] " "
        a_ [ href_ "https://www.youtube.com/@moperatico"
           , class_ "btn btn-info btn-lg"]
          "Math YouTube channel"
        p_ [] " "
        a_ [ href_ "https://www.youtube.com/@mopercode"
           , class_ "btn btn-info btn-lg"]
          "Coding YouTube channel"
