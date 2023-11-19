{
	description = "Dev environment for `memtree`";

	inputs = {
		# Actual versions are pinned in lockfile
		flake-utils.url = "github:numtide/flake-utils";
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

		# Allow users of the flake to override the set of supported systems
		systems.url = "github:nix-systems/default-linux";
		flake-utils.inputs.systems.follows = "systems";
	};

	outputs = { flake-utils, nixpkgs, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				pkgs = import nixpkgs { inherit system; };
				inherit (pkgs) lib;

				inherit (pkgs.callPackage ./.nix/package.nix {}) dependencies memtree;
				env = import ./.nix/env.nix { inherit pkgs; };
			in rec {
				checks.devour = with lib; let
					drvs = concatMap attrValues [ packages devShells ];
				in
					pkgs.writeText "memtree-flake-outputs" (concatLines drvs);

				packages = {
					default = memtree;
				};

				ci = with lib; pipe ./.ci/tasks.json [
					importJSON
					(filterAttrs (_: t: ! t?system || t.system == system))
					(mapAttrs (name: t: env {
						inherit name;
						groups = t.groups or [];
						extras = attrVals (t.extras or []) pkgs;
						text = concatStringsSep "\n" t.script;
					}))
				];

				apps = with lib; mapAttrs (_: drv: { type = "app"; program = getExe drv; }) ci;

				devShells = with lib.attrsets; unionOfDisjoint
					(mapAttrs (_: x: x.override { text = null; }) ci) {
					default = env {
						groups = lib.attrNames dependencies;  # All dependencies groups
						extras = with pkgs; [
							deadnix jq
							python3Packages.ipython
							poetry
							ruff
							yamllint
						];
					};
				};
	});
}
