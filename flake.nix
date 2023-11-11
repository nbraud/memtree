{
	description = "Dev environment for `memtree`";

	inputs = {
		# Actual versions are pinned in lockfile
		devour-flake.url = "github:srid/devour-flake";
		flake-utils.url = "github:numtide/flake-utils";
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

		# We are using `devour-flake` as a package
		devour-flake.flake = false;
	};

	outputs = { devour-flake, flake-utils, nixpkgs, ... }:
		# TODO: Figure out the whole nix-systems/linux thing
		flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system:
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
