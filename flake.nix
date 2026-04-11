{
  description = "Hamlet-free Lucid Yesod app";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self
                   , nixpkgs
                   , flake-utils
                   , haskellNix
                   , flake-compat
                   }:
    let
      overlays =
        [ haskellNix.overlay
          (final: prev:
            let
              devEnv = ''
                export YESOD_PORT=3000
              '';
            in {
              blog = final.haskell-nix.cabalProject {
                src = final.haskell-nix.cleanSourceHaskell {
                  src = ./.;
                  name = "blog";
                };
                compiler-nix-name = "ghc966";
                shell.tools = {
                  cabal = {};
                  haskell-language-server = {};
                  ghcid = {};
                  hlint = {};
                  stylish-haskell = {};
                };
                shell.shellHook = devEnv;
              };
              blog-wrapper = pkgs.writeShellApplication {
                name = "blog-wrapped";
                runtimeInputs = [ self.packages.x86_64-linux.default ];
                text = ''
                  cd ~/blog
                  touch src/Settings/StaticFiles.hs
                  ${self.packages.x86_64-linux.default}/bin/blog
                '';
              };
              blog-dev = pkgs.writeShellApplication {
                name = "blog-dev";
                runtimeInputs = final.lib.flatten [
                  final.blog.shell.nativeBuildInputs
                  final.blog.shell.buildInputs
                ];
                text = ''
                    ${devEnv}
                    
                    ghcid \
                          --command '(echo ":l src/Application.hs" && cat) | cabal v2-repl' \
                          --test appMain \
                          --warnings --restart="src" --restart="app"
                  '';
              };
            }
          )
        ];
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        inherit overlays;
        inherit (haskellNix) config;
      };
      flake = pkgs.blog.flake{};
      in
        flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: flake //{
          packages = flake.packages // {
            default = flake.packages."blog:exe:blog";
            blog-wrapper = pkgs.blog-wrapper;
            blog-dev = pkgs.blog-dev;
          };
          apps = flake.apps // {
            default = flake.apps."blog:exe:blog";
            dev = {
              type = "app";
              program = "${pkgs.blog-dev}/bin/blog-dev";
            };
          };
          legacyPackages = pkgs;
        });
  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}