{
  description = "Haskell project template";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    templates = {
      hpack = {
        path = ./hpack;
        description = "Haskell Project based on hpack";
      };
      default = self.templates.hpack;
    };
  };
}
