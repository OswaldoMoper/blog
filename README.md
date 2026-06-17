# Oswaldo Moper Blog

A minimal, Hamlet‑free Yesod blog built with **Lucid**, **Nix flakes**, and **Haskell**.  
This project is my personal website and a playground for experimenting with clean, type‑safe web development.

## ✨ Features

- 🚫 No Hamlet — fully rendered with **Lucid** templates
- 📦 Reproducible builds with **Nix flakes**  
- 🔒 Strongly typed routes and templates  
- 🎨 Custom layout without Yesod widgets  
- 🚀 Ready for deployment with Nginx + systemd or GitHubPages

## 💡 Why Lucid?

- Full type‑safety without Template Haskell
- Explicit HTML structure
- Easier integration with Nix tooling
- No quasi‑quoters or hidden magic
- More control over layout and rendering

## 🛠 Tech Stack

- **Haskell / Yesod**
- **Lucid** for HTML rendering
- **Nix flakes** for reproducible dev environments
- **Haskell flake** for fully reproducible GHC, Cabal, and toolchain pinning
- **Cabal** for local builds
- **Bootstrap 5** (via CDN) for styling

## 📁 Project Structure

```markdown
├── app/
│   ├── devel.hs
│   ├── DevelMain.hs
│   └── main.hs
├── config/
│   ├── favicon.ico
│   ├── robots.txt
│   ├── routes.yesodroutes
│   ├── settings.yml
│   └── test-settings.yml
├── src/
│   ├── Handlers/
│   ├── Import/
│   │   └── NoFoundation.hs
│   ├── LucidTemplates/
│   ├── Settings
│   │   └── StaticFiles.hs
│   ├── Application.hs
│   ├── Foundation.hs
│   ├── Import.hs
│   ├── Settings.hs
│   └── Types.hs
├── static/
│   ├── css/
│   └── js/
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

## 🚀 Deployment

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
