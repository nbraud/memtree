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
				pkgs = import nixpkgs {
					inherit system;
					config.allowAliases = false;
				};

				inherit (pkgs) lib;
				inherit (lib.importTOML ./pyproject.toml) bork tool;

				minVersion = "3.10";  # TODO extract from pyproject.toml
				pythonInterpreters = lib.filterAttrs (_: pyDrv: lib.all lib.id [
					(lib.isDerivation pyDrv)
					(lib.versionAtLeast pyDrv.version minVersion)
					(!pyDrv.isPyPy)  # HACK due to poetry-core incompatibility
				]) (pkgs.pythonInterpreters // {
					default = pkgs.python3;
				});

			in rec {
				checks.devour = with lib; let
					drvs = concatMap attrValues [ packages ]; # FIXME devShells
				in
					pkgs.writeText "memtree-flake-outputs" (concatLines drvs);

				packages = lib.mapAttrs (_: py: py.pkgs.buildPythonApplication {
					pname = "memtree";
					inherit (tool.poetry) version;

					format = "pyproject";
					src = with lib.fileset;
						toSource {
							root = ./.;
							fileset = unions [
								./pyproject.toml
								./memtree
								./tests
							];
						};

					build-system = with py.pkgs; [
						poetry-core
					];

					dependencies = with py.pkgs; [
						rich
					];

					nativeCheckInputs = with py.pkgs; [
						hypothesis
						pytestCheckHook
					];
					pytestFlagsArray = [ "-v" ];
					pythonImportsCheck = [ "memtree" ];

					passthru.interpreter = py;
					meta.platforms = lib.platforms.linux;
				}) pythonInterpreters;

				apps = lib.mapAttrs (cmd: txt: {
					type = "app";
					program = toString (pkgs.writeShellScript "memtree-${cmd}" txt);
				}) {
					lint = ''
						export PATH=${lib.makeBinPath [ pkgs.python3.pkgs.bork pkgs.ruff ]}
						exec bork run lint
					'';
					deadnix = ''
						export PATH=${lib.makeBinPath (with pkgs; [ deadnix jq ])}
						deadnix -h --output-format json | \
							jq -cf ${toString ./.ci/deadnix.jq} > deadnix.json

						# If output was produced, rerun to get a human-readable version too
						! [ -s ./deadnix.json ] || \
							deadnix -h --fail
					'';
				};

				devShells = lib.mapAttrs (_: memtree: pkgs.mkShell {
					nativeBuildInputs = [
						pkgs.deadnix
						pkgs.yamllint
						(memtree.interpreter.withPackages (pyPkgs: with pyPkgs; [
							ipython
							pytest
						] ++ memtree.build-system ++ memtree.dependencies))
					];
				}) packages;

	});
}
