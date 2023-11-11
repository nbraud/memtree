{
	description = "Dev environment for `memtree`";

	inputs = {
		# Actual versions are pinned in lockfile
		devour-flake.url = "github:srid/devour-flake";
		flake-utils.url = "github:numtide/flake-utils";
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

		# We are using `devour-flake` as a package
		devour-flake.flake = false;

		# Allow users of the flake to override the set of supported systems
		systems.url = "github:nix-systems/default-linux";
		flake-utils.inputs.systems.follows = "systems";
	};

	outputs = { devour-flake, flake-utils, nixpkgs, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let pkgs = import nixpkgs { inherit system; };
			in {
				packages = with pkgs; {
					default = (callPackage ./package.nix {}).memtree;
					devour-self = writeShellScriptBin "devour-self" ''
						exec ${lib.getExe (callPackage devour-flake {})} "$PWD" "$@"
					'';
					extraneous = with lib; pipe (callPackage ./extra-dependencies.nix {}) [
						attrNames
						(filter (pname: pkgs ? pname || python3Packages ? pname))
						(concatStringsSep ", ")
						(writeText "extraneous.json")
					];
				};

				devShells.ci      = import ./ci.nix    { inherit pkgs; };
				devShells.default = import ./shell.nix { inherit pkgs; };
			});
}
