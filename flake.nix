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

				inherit (pkgs.callPackage ./.nix/package.nix {}) dependencies memtree;
				bork = (lib.importTOML ./pyproject.toml).tool.bork;
				env = import ./.nix/env.nix { inherit pkgs; };
			in rec {
				packages = with pkgs; {
					default = memtree;

					# TODO: Convert into “apps”
					devour-self = writeShellScriptBin "devour-self" ''
						exec ${lib.getExe (callPackage devour-flake {})} "$PWD" "$@"
					'';
					test = env {
						groups = [ "run" "test" ];
						text   = "exec ${bork.aliases.test}";
					};
					lint-py = env {
						extras = [ ruff ];
						text   = "exec ${bork.aliases.lint}";
					};
					lint-nix = env {
						extras = [ deadnix jq ];
						text = ''
							deadnix -h --output-format json | \
								jq -cf ./.ci/deadnix.jq > deadnix.json

							# If output was produced, rerun to get a human-readable version too
							! [ -s ./deadnix.json ] || \
								deadnix -h --fail
						'';
					};
					lint-yaml = env {
						extras = [ yamllint ];
						text = ''
							yamllint ./.cirrus.yml
						'';
					};
				};

				devShells = with lib; mapAttrsRecursiveCond
					(x: !(isDerivation x))
					(_: x: if isDerivation x then x.override { text = null; } else x)
					{ inherit (packages) lint-py lint-nix lint-yaml test; }
				// {
					default = env {
						groups = lib.attrNames dependencies;  # All dependencies groups
						extras = with pkgs; [
							deadnix
							python3Packages.ipython
							poetry
							yamllint
						];
      	  };
				};
	});
}
