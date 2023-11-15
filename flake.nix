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
			let
				pkgs = import nixpkgs { inherit system; };
				inherit (pkgs) lib;

				env = import ./.nix/env.nix { inherit pkgs; };
				bork = (lib.importTOML ./pyproject.toml).tool.bork;
			in rec {
				packages = with pkgs; {
					default = (callPackage ./.nix/package.nix {}).memtree;

					# TODO: Convert into “apps”
					devour-self = writeShellScriptBin "devour-self" ''
						exec ${lib.getExe (callPackage devour-flake {})} "$PWD" "$@"
					'';
					lint = env {
						extras = [ python3 ];
						groups = [ "lint" ];
						text   = "exec ${bork.aliases.lint}";
					};
					test = env {
						extras = [ python3 ];
						groups = [ "run" "test" ];
						text   = "exec ${bork.aliases.test}";
					};
				};

				devShells = lib.genAttrs [ "lint" "test" ] (name:
					packages.${name}.override { text = null; }
				) // {
					default = import ./shell.nix { inherit pkgs; };
				};
			});
}
