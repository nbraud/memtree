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

	outputs = { self, devour-flake, flake-utils, nixpkgs }:
		# TODO: Figure out the whole nix-systems/linux thing
		flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system:
			let pkgs = import nixpkgs { inherit system; };
			in {
				packages = with pkgs; {
					default = (callPackage ./package.nix {}).memtree;
					devour-self = let
						# Work around devour-flake#19
						devour = (callPackage devour-flake {}).override (super: {
							runtimeInputs = super.runtimeInputs ++ [ findutils ];
						});
					in writeShellScriptBin "devour-self" ''
						exec ${lib.getExe devour} ${builtins.toString ./.} "$@"
					'';
				};

				devShells.ci      = import ./ci.nix    { inherit pkgs; };
				devShells.default = import ./shell.nix { inherit pkgs; };
			});
}
