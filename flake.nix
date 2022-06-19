{
  description = "Lowering a surface syntax into different intermediate representations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      packageName = "lower";
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = (final: prev: {
        ${packageName} = final.haskellPackages.callCabal2nix packageName ./. {};
      });

      packages = forAllSystems (system: {
        ${packageName} = nixpkgsFor.${system}.${packageName};
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.${packageName});

      checks = self.packages;

      devShell = forAllSystems (system: let haskellPackages = nixpkgsFor.${system}.haskellPackages;
        in haskellPackages.shellFor {
          packages = p: [self.packages.${system}.${packageName}];
          withHoogle = false;
          buildInputs = with haskellPackages; [
            haskell-language-server
            ghcid
            cabal-install
          ];
        });
  };
}