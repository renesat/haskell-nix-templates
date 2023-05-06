{

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        runInputs = [ ];

        # For adding tools, depends and other stuff use pkgs.haskell.lib.*
        hello-world = pkgs.haskellPackages.developPackage {
          root = self;
          name = "hello-world";
          cabal2nixOptions = "--hpack";
        };

        stack-nix-integration = pkgs.writeText "stack-nix-integration.nix" ''
          {ghc}:
          let
            pkgs = import ${pkgs.path} {};
          in pkgs.haskell.lib.buildStackProject {
            inherit ghc;
            name = "hello-world";
            buildInputs = with pkgs; [
            ];
          }
        '';

        # Source: https://www.tweag.io/blog/2022-06-02-haskell-stack-nix-shell/
        stack-wrapped = pkgs.symlinkJoin {
          name = "stack";
          paths = [ pkgs.stack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/stack \
              --add-flags "\
                --nix \
                --no-nix-pure \
                --nix-shell-file="${stack-nix-integration}"\
              "
          '';
        };

      in {
        packages = {
          inherit hello-world;
          default = hello-world;
        };
        apps = {
          hello-world = {
            type = "app";
            program = "${hello-world}/bin/hello-world-exe";
          };
          defalut = self.apps."${system}".hello-world;
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs;
              [
                # Slack
                stack-wrapped

                # Tools
                haskellPackages.hasktags
                haskellPackages.fourmolu
                haskell-language-server
                nixfmt

              ] ++ runInputs;
            NIX_PATH = "nixpkgs=" + pkgs.path;
          };
        };
      });
}
