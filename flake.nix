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
      compilerVersion = "ghc943";
      pkgs = nixpkgs.legacyPackages.${system};
      hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
        overrides = hfinal: hprev: {
          hsplayground = hfinal.callCabal2nix "hsplayground" ./. {};
        };
      };
    in rec {
      packages =
        utils.flattenTree
        {hsplayground = hsPkgs.hsplayground;};

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
            hsPkgs.haskell-language-server
            haskellPackages.cabal-install
            cabal2nix
            haskellPackages.ghcid
            haskellPackages.fourmolu
            haskellPackages.cabal-fmt
            nodePackages.serve
          ]
          ++ (builtins.attrValues (import ./scripts.nix {s = pkgs.writeShellScriptBin;}));
      };

      # nix build
      defaultPackage = packages.hsplayground;
    });
}
