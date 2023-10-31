{
  description = "Dev environment for `memtree`";

  inputs = {
    # Actual versions are pinned in lockfile
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, nixpkgs }:
    # TODO: Figure out the whole nix-systems/linux thing
    flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system: {
      packages.default =
        with import nixpkgs { inherit system; };
        callPackage ./package.nix {};

      packages.ci =
        import ./ci.nix { pkgs = nixpkgs.legacyPackages.${system}; };

      devShells.default =
        import ./shell.nix { pkgs = nixpkgs.legacyPackages.${system}; };
    });
}
