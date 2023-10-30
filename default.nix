{ pkgs ? import <nixpkgs> {}}:
with pkgs;

let
	py = python3;
	python3Packages = py.pkgs;

	drv = callPackage ./package.nix { inherit python3Packages; };
	extraDependencies = callPackage ./extra-dependencies.nix { inherit python3Packages; };

	devTools = with lib; pipe ./pyproject.toml [
		readFile
		builtins.fromTOML
		(attrByPath [ "tool" "poetry" "dev-dependencies" ] {})
		attrNames
		(names: attrVals names (extraDependencies // python3Packages))
	];

in
mkShell {
	nativeBuildInputs = [
		drv
		poetry
		python3Packages.poetry-core
		py
	] ++ devTools;
}
