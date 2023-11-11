{
	description = "Dev environment for `memtree`";

	inputs = {
		# Actual versions are pinned in lockfile
		flake-utils.url = "github:numtide/flake-utils";
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
	};

	outputs = { self, flake-utils, nixpkgs }:
		# TODO: Figure out the whole nix-systems/linux thing
		flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system:
			let pkgs = import nixpkgs { inherit system; };
			in {
				packages.default = (pkgs.callPackage ./package.nix {}).memtree;

				devShells.ci      = import ./ci.nix    { inherit pkgs; };
				devShells.default = import ./shell.nix { inherit pkgs; };
			});
}
