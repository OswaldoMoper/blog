# Oswaldo Moper Blog

A minimal, Hamlet‑free Yesod blog built with **Lucid**, **Nix flakes**, and **Haskell**.  
This project is my personal website and a playground for experimenting with clean, type‑safe web development.

It runs in **two modes** from the same codebase: a dynamic **Yesod (Warp)** server,
and a **static‑site generator** that renders the same pure Lucid templates to plain
HTML and ships it to **GitHub Pages** at [oswaldomoper.com](https://oswaldomoper.com).

## ✨ Features

- 🚫 No Hamlet — fully rendered with **Lucid** templates
- 📦 Reproducible builds with **Nix flakes**  
- 🔒 Strongly typed routes and templates  
- 🎨 Custom layout without Yesod widgets  
- 📝 Markdown content (`content/pages/`) rendered with **cmark‑gfm**
- 🌐 Static site generation (`static-gen`) deployed to **GitHub Pages** via **GitHub Actions + Nix**
- 🚀 Or run as a dynamic Yesod server behind Nginx + systemd

## 💡 Why Lucid?

- Full type‑safety without Template Haskell
- Explicit HTML structure
- Easier integration with Nix tooling
- No quasi‑quoters or hidden magic
- More control over layout and rendering

## 🛠 Tech Stack

- **Haskell / Yesod**
- **Lucid** for HTML rendering
- **cmark-gfm** for Markdown content rendering
- **Nix flakes** for reproducible dev environments
- **Haskell flake** for fully reproducible GHC, Cabal, and toolchain pinning
- **Cabal** for local builds
- **Bootstrap 3.3.7** (via CDN) for styling
- **GitHub Actions + GitHub Pages** for static deployment

## 📁 Project Structure

```markdown
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI: build static site with Nix, deploy to Pages
├── app/                        # dynamic Yesod (Warp) server entrypoints
│   ├── DevelMain.hs
│   └── main.hs
├── config/
│   ├── favicon.ico
│   ├── robots.txt
│   ├── routes.yesodroutes
│   ├── settings.yml
│   └── test-settings.yml
├── content/
│   └── pages/                  # Markdown content (YAML front-matter + body)
│       └── about.md
├── gen/                        # static-site generator (does NOT start Warp)
│   ├── Content.hs              # Markdown + front-matter parsing
│   └── Main.hs                 # renders templates to ./_site
├── src/
│   ├── Handler/
│   ├── Import/
│   │   └── NoFoundation.hs
│   ├── LucidTemplates/         # shared pure Lucid templates (server + generator)
│   ├── StaticGen/
│   │   └── StaticLayout.hs     # route/server-free layout used by the generator
│   ├── Settings/
│   │   └── StaticFiles.hs
│   ├── Application.hs
│   ├── Foundation.hs
│   ├── Import.hs
│   ├── Settings.hs
│   └── Types.hs
├── static/
│   └── css/
├── test/
│   ├── Handler/
│   ├── Spec.hs
│   └── TestImport.hs
├── blog.cabal
├── flake.lock
└── flake.nix
```

## 🚧 Development

Be sure that ```approot:"``` line on ```config/settings.yml``` is commented (approot will default to localhost, which we want for a local deployment).

You can start a dev shell using direnv and nix-direnv. You just need to authorize it by running:

```sh
direnv allow
```

Alternatively, you can use:

```sh
nix develop
```

The dev shell includes `cabal`, `ghcid`,`haskell-language-server`, `hlint`, and other tools pinned via haskell flake toolchain.

Run the live-reloading development server:

```sh
nix run .#dev
```

This launches a live‑reloading development loop using `ghcid` + `cabal repl`. As your code changes, your site will be automatically recompiled and redeployed to localhost.

## 🧪 Tests

```sh
nix develop
cabal test --flag library-only --flag dev
```

## 🌐 Static site & GitHub Pages

The same templates that the live server renders can be emitted as a **static site**
served by GitHub Pages. The `static-gen` executable (in `gen/`) reuses the pure
Lucid templates — it never starts Warp — and writes the home page, every Markdown
page under `content/pages/`, the CSS/favicon, plus a `CNAME`, `robots.txt` and
`404.html`.

Content lives in `content/pages/*.md` with a small YAML front-matter:

```markdown
---
title: "Work with me"
description: "Senior Haskell / Nix engineer…"
slug: about
---

# Markdown body…
```

Build it:

```sh
# local iteration — writes ./_site
nix run .#gen

# hermetic, reproducible build (what CI uses)
nix build .#static-site
```

Preview locally (absolute asset paths need a server rooted at the output):

```sh
nix run nixpkgs#python3 -- -m http.server 8080 --directory _site
```

### CI deployment

On every push to `master`, [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)
builds `.#static-site` with Nix and publishes it with the official Pages actions
(`upload-pages-artifact` + `deploy-pages`). Philosophy: **thin YAML, fat flake** —
all build logic lives in `flake.nix` (`packages.static-site`), the workflow only
orchestrates.

## 🚀 Dynamic server deployment (alternative)

Use this when running the full Yesod (Warp) server instead of the static site.

### Prerequisites

1. Have a Cloud Console account with the credentials specified for the project (project, serviceAccount, accessKey) or change accordingly.
2. Have a record pointing to ```<this-yesod-app-name-dns>``` (```@````), or change the nginx options on /nixosModules/Nginx.nix accordingly.

### Steps

#### 1. Check flake and build

```sh
  cd /path/to/project/<this-yesod-app-name>
  git checkout <release-name>
```

Comment and change local configs on ```config/settings.yml``` to main configs.

```sh
  nix develop -c {your shell}
  nix flake show --allow-import-from-derivation
  nix build
  exit
```

The resulting binary will be available at:

```sh
./result/bin/blog
```

If the build test doesn't work, go back to the main branch and make the necessary changes and repeat from local deploy test.

#### 2. Upgrade at Server

1. Deploy the resulting binary + static files to your server
2. Serve behind webStack (see [`nixosModules/webStack.nix`](https://github.com/OswaldoMoper/NixosConfig/blob/spartan/docs/modules/webstack.md))

## 📚 Documentation

- Check [nix.dev](https://nix.dev/) for the official documentation for the Nix ecosystem.
- Read the [Yesod Book](https://www.yesodweb.com/book) online for free
- Browse package documentation on:
  - [Hackage](https://hackage.haskell.org/)  
  - Or search functions/types using [Hoogle](https://hoogle.haskell.org/)
- For local documentation, use:
  - `cabal haddock --open` to generate Haddock documentation for your dependencies, and open that documentation in a browser
- The [Yesod cookbook](https://github.com/yesodweb/yesod-cookbook) has sample code for various needs

## 💬 Getting Help

- Ask questions and check other forums on [NixOS Discourse](https://discourse.nixos.org/)
- Ask the [Yesod Google Group](https://groups.google.com/forum/#!forum/yesodweb)
- Ask for help on [Functional Programming Slack](https://fpchat-invite.herokuapp.com/), in the #haskell, #haskell-beginners, or #yesod channels.

## 📄 Credits and Licenses

This project includes code derived from [YesodWeb/Yesod](https://github.com/yesodweb/yesod), which is licensed under the [MIT License](https://github.com/yesodweb/yesod/blob/master/LICENSE).
Additional modifications and original code in this repository are licensed under the [BSD 3-Clause License](./LICENSE).

## 👤 About

I’m Oswaldo Moper — Haskell and Nix enthusiast, speaker, and open‑source contributor.
This blog is where I share about functional programming, reproducible systems, and software design.
