{ lib
, callPackage
, poetry
, python3Packages
, ... }:

let
	inherit (python3Packages) buildPythonApplication;

	pyproject = with builtins; fromTOML (readFile ./pyproject.toml);
	inherit (pyproject.tool) poetry;

	extraDependencies = callPackage ./extra-dependencies.nix {};
in

buildPythonApplication {
	pname = poetry.name;
	pyproject = true;
	inherit (pyproject.tool.poetry) version;

	nativeBuildInputs = with python3Packages; [
		poetry-core
	];

	propagatedBuildInputs = with lib; pipe poetry.dependencies [
		attrNames
		(remove "python")
		(names: attrVals names python3Packages)
	];

	nativeCheckInputs = with lib; pipe poetry.dev-dependencies [
		attrNames
		(names: attrVals names (extraDependencies // python3Packages))
	];

	src = ./.;

	checkPhase = ''
		bork run lint
		bork run test
	'';

	pythonImportChecks = [ "memtree" ];
}
