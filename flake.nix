{
  description =
    "Lowering a surface syntax into different intermediate representations";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Flake
    #shs.url = "github:luc-tielen/souffle-haskell/c46d0677e4bc830df89ec1de2396c562eb9d86d3";

    # Non-flake
    #alga.url = "github:snowleopard/alga/75de41a4323ab9e58ca49dbd78b77f307b189795";
    #alga.flake = false;
  };
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    with nixpkgs.lib;
    with flake-utils.lib;
    eachDefaultSystem (system:
      let
        packageName = "lower";
        ghcVersion = "902";
        config = {
          allowUnfree = false;
          allowBroken = true;
          allowUnsupportedSystem = false;
        };
        overlay = final: _:
          let
            haskellPackages =
              final.haskell.packages."ghc${ghcVersion}".override {
                overrides = hf: hp: # final, previous
                  with final.haskell.lib; rec {
                    # Examples:
                    #dependent-hashmap = with hf; unmarkBroken (dontCheck hp.dependent-hashmap);
                    #haddock-api = with hf; doJailbreak (callHackage "haddock-api" "2.21.0" {}); # From Hackage
                    #BinderAnn = with hf; callHackageDirect { pkg = "BinderAnn"; ver = "0.1.0.0"; sha256 = "..."; } {}; # Works for *any* version released on Hackage, not only those before our version of all-cabal-hashes.
                    #algebraic-graphs = with hf; dontCheck (callCabal2nix "algebraic-graphs" (inputs.alga) { }); # Non-flake input
                    #inherit (shs.packages."${system}") souffle-haskell; # Flake input

                    ${packageName} = with hf; (callCabal2nix packageName ./. { });
                  };
              };
          in { inherit haskellPackages; };
        pkgs = import nixpkgs {
          inherit system config;
          overlays = [
            #shs.overlay."${system}" # Flake
            overlay
          ];
        };
        haskellPackages = pkgs.haskellPackages;

      in with pkgs.lib; rec {
        inherit overlay;

        packages.${packageName} = haskellPackages.${packageName};

        defaultPackage = packages.${packageName};

        devShell = haskellPackages.shellFor {
          withHoogle = false; # provides docs; optional.
          packages = p: [
            p.${packageName}
          ];
          buildInputs = with haskellPackages; [
            cabal-install
            ghcid
            haskell-language-server
            hlint
          ];
        };
      });
}