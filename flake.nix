{
  description = "hsplayground";

  inputs = {
    # Nix Inputs
    nixpkgs.url = github:nixos/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    pre-commit-hooks.url = github:cachix/pre-commit-hooks.nix;
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
      nixpkgs,
      pre-commit-hooks,
      flake-utils,
  }: let
    utils = flake-utils.lib;
  in
    utils.eachDefaultSystem (system: let
      compilerVersion = "ghc925";

      pkgs = nixpkgs.legacyPackages.${system};
      hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
        overrides = hfinal: hprev: {
          hsplayground = hfinal.callCabal2nix "hsplayground" ./. {};
          htoml =
            let patch = pkgs.fetchpatch {
                  url = "https://github.com/mirokuratczyk/htoml/compare/f776a75eda018b6885bfc802757cd3ea3d26c7d7..33971287445c5e2531d9605a287486dfc3cbe1da.patch";
                  sha256 = "sha256-vERVaxVO7wAd0u5PmvBLRXXMuixzV3LPgiGvtWJVJbI=";
                };
            in pkgs.haskell.lib.unmarkBroken (pkgs.haskell.lib.appendPatch hprev.htoml patch);
        };
      };
    in rec {
      packages =
        utils.flattenTree
          {hsplayground = hsPkgs.hsplayground;
           htoml = hsPkgs.htoml;
          };

      # nix flake check
      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            fourmolu.enable = true;
            cabal-fmt.enable = true;
          };
        };
      };

      # nix develop
      devShell = hsPkgs.shellFor {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        withHoogle = true;
        packages = p: [
          p.hsplayground
        ];
        buildInputs = with pkgs;
          [
            cabal2nix
            haskellPackages.cabal-fmt
            haskellPackages.hasktags
            haskellPackages.cabal-install
            haskellPackages.fourmolu
            haskellPackages.ghcid
            hsPkgs.haskell-language-server
            nodePackages.serve
          ]
          ++ (builtins.attrValues (import ./scripts.nix {s = pkgs.writeShellScriptBin;}));
      };

      # nix build
      defaultPackage = packages.hsplayground;

    });
}
