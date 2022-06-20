{
  description =
    "Lowering a surface syntax into different intermediate representations";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
                    ${packageName} = with hf; (callCabal2nix packageName ./. { });
                  };
              };
          in { inherit haskellPackages; };
        pkgs = import nixpkgs {
          inherit system config;
          overlays = [
            overlay
          ];
        };
        haskellPackages = pkgs.haskellPackages;

      in with pkgs.lib; rec {
        inherit overlay;

        packages.${packageName} = haskellPackages.${packageName};

        defaultPackage = packages.${packageName};

        devShell = haskellPackages.shellFor {
          packages = p: [
            p.${packageName}
          ];
          buildInputs = with haskellPackages; [
            cabal-install
            ghcid
            haskell-language-server
            hlint
            hpack
          ];
        };
      });
}