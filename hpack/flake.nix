{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-root.url = "github:srid/flake-root";
    mission-control.url = "github:Platonic-Systems/mission-control";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.flake-root.flakeModule
        inputs.mission-control.flakeModule
      ];
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem = {
        self',
        system,
        lib,
        config,
        pkgs,
        ...
      }: {
        haskellProjects.default = {
          devShell = {
            # TODO: Remove this after https://github.com/numtide/treefmt-nix/issues/65
            tools = hp:
              {
                hpack = hp.hpack;
                treefmt = config.treefmt.build.wrapper;
              }
              // config.treefmt.build.programs;
            hlsCheck.enable = false;
          };
          autoWire = ["packages" "apps" "checks"];
        };

        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          package = pkgs.treefmt;

          programs.ormolu.enable = true;
          programs.ormolu.package = pkgs.haskellPackages.fourmolu_0_12_0_0;
          programs.alejandra.enable = true;
          programs.hlint.enable = true;
        };

        mission-control.scripts = {
          repl = {
            description = "Start the cabal repl";
            exec = ''
              cabal repl "$@"
            '';
            category = "Dev Tools";
          };
          fmt = {
            description = "Format the source tree";
            exec = config.treefmt.build.wrapper;
            category = "Dev Tools";
          };
          build = {
            description = "Build all";
            exec = ''
              cabal build
            '';
            category = "Dev Tools";
          };
        };

        packages.default = self'.packages.hello-world;
        apps.default = self'.apps.hello-world-exe;

        devShells.default = pkgs.mkShell {
          name = "hello-world";
          inputsFrom = [
            config.haskellProjects.default.outputs.devShell
            config.flake-root.devShell
            config.mission-control.devShell
          ];
        };
      };
    };
}
