{
  description = "Hamlet-free Lucid Yesod app";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs = inputs@{ self
                   , nixpkgs
                   , flake-parts
                  , ...
                   }:
    let
      devEnv = ''
        export YESOD_PORT=3000
        echo "DEV Port: $YESOD_PORT"
      '';
    in
      flake-parts.lib.mkFlake { inherit inputs; } {
        systems = [ "x86_64-linux" ];
        imports = [ inputs.haskell-flake.flakeModule ];
        perSystem = {self', system, lib, config, pkgs, ...}: {
          haskellProjects.default = {
            projectRoot = ./.;
            basePackages = pkgs.haskell.packages.ghc96;
            devShell = {
              tools = hp: {
                cabal = hp.cabal-install;
                hlint = hp.hlint;
                haskell-language-server = hp.haskell-language-server;
                stylish-haskell = hp.stylish-haskell;
              };
              hlsCheck.enable = false;
              mkShellArgs = {
                nativeBuildInputs = with pkgs; [
                  haskell.packages.ghc96.yesod-bin
                  postgresql
                ];
                shellHook = devEnv;
              };
            };
          };

          packages = {
            default = config.haskellProjects.default.outputs.packages.blog.package;
            blog-wrapper = pkgs.writeShellApplication {
              name = "blog-wrapped";
              runtimeInputs = [ self'.packages.default ];
              text = ''
                cd ~/blog
                touch src/Settings/StaticFiles.hs
                blog
              '';
            };
            blog-dev = pkgs.writeShellApplication {
              name = "blog-dev";
              runtimeInputs = (with config.haskellProjects.default.outputs.devShell; 
                nativeBuildInputs ++ buildInputs
              ) ++ [ pkgs.ghcid pkgs.cabal-install ];
              text = ''
                ${devEnv}
                ghcid \
                  --command '(echo ":l src/Application.hs" && cat) | cabal v2-repl' \
                  --test appMain \
                  --warnings --restart="src" --restart="app"
              '';
            };
          };
          apps = {
            default = config.haskellProjects.default.outputs.apps.blog;
            dev = {
              type = "app";
              program = "${self'.packages.blog-dev}/bin/blog-dev";
            };
          };
          legacyPackages = pkgs;
        };
      };
  nixConfig = {
    allow-import-from-derivation = true; 
  };
}