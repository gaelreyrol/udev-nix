{
  description = "A trivial but enhanced flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "unstable";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs-stable.follows = "nixpkgs";
    pre-commit-hooks.inputs.nixpkgs.follows = "unstable";
  };

  outputs = { self, nixpkgs, unstable, treefmt-nix, pre-commit-hooks, ... }:
    let
      overlays = [
        (final: prev: {
          unstable = import unstable {
            inherit (prev) system;
          };
        })
      ];
      forSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
        ]
          (system:
            function {
              inherit system;
              pkgs = import nixpkgs {
                inherit system overlays;
              };
            }
          );
      udevTests = { system, pkgs }: import ./tests {
        inherit pkgs;
        udev = self.lib.${system};
      };
    in
    {
      formatter = forSystems ({ pkgs, system }: treefmt-nix.lib.mkWrapper pkgs.unstable {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
      });

      # For testing purposes, udevTests result is not a derivation.
      # packages = forSystems ({ pkgs, system }: udevTests { inherit pkgs system; });

      checks = forSystems ({ pkgs, system }:
        let
          udevTestsResults = builtins.mapAttrs (name: test: test.result) (udevTests { inherit pkgs system; });
        in
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              editorconfig-checker.enable = true;
              actionlint.enable = true;
            };
          };
        } // udevTestsResults
      );

      devShells = forSystems ({ pkgs, system }: {
        default = pkgs.mkShell {
          packages = [
            pkgs.unstable.statix
            pkgs.unstable.treefmt
            pkgs.unstable.editorconfig-checker
            pkgs.unstable.actionlint
          ];
          inherit (self.checks."${system}".pre-commit-check) shellHook;
        };
      });

      lib = forSystems ({ pkgs, system }: import ./src { inherit pkgs; });
    };
}
