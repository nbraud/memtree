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

	inherit (lib) hasPrefix head mapAttrsToList substring;

	versionCheck = dVer: versionSpec:
		with lib.versions;
		if hasPrefix "^" versionSpec then
			# SemVer comparison
			let sVer = substring 1 (-1) versionSpec; in
			if major sVer != 0 then
				(major dVer) == (major sVer) &&
				(splitVersion dVer) >= (splitVersion sVer)
			else
				(major dVer) == 0 &&
				(minor dVer) == (minor sVer) &&
				(splitVersion dVer) >= (splitVersion sVer)

		else
			throw "Unimplemented comparison operator in `${versionSpec}`";

	fromPoetryDeps = mapAttrsToList
		(name: spec:
			let drv = (extraDependencies // python3Packages).${name}; in
			if versionCheck drv.version spec then
				drv
			else
				throw "Package '${name}' at version '${drv.version}' does not meet spec '${spec}'");
in

rec {
	dependencies = fromPoetryDeps (builtins.removeAttrs poetry.dependencies ["python"]);
	dev-dependencies = fromPoetryDeps poetry.dev-dependencies;

	memtree = buildPythonApplication {
		pname = poetry.name;
		pyproject = true;
		inherit (pyproject.tool.poetry) version;

		nativeBuildInputs = with python3Packages; [
			poetry-core
		];

		propagatedBuildInputs = dependencies;
		nativeCheckInputs = dev-dependencies;

		src = with lib.fileset;
			toSource {
				root = ./.;
				fileset = unions [
					./pyproject.toml
					./memtree
					./tests
				];
			};

		checkPhase = ''
			bork run lint
			bork run test
		'';

		pythonImportChecks = [ "memtree" ];
	};
}
