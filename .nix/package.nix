{ lib
, python3Packages
, ruff
}:

let
	inherit (python3Packages) buildPythonApplication;

	pyproject = with builtins; fromTOML (readFile ../pyproject.toml);
	inherit (pyproject.tool) poetry;

	inherit (lib) hasPrefix mapAttrsToList substring;

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
			let drv = python3Packages.${name} or (assert name == "ruff"; ruff); in
			if versionCheck drv.version spec then
				drv
			else
				throw "Package '${name}' at version '${drv.version}' does not meet spec '${spec}'");

	dependenciesByGroup = with lib; mapAttrs
		(_: x: fromPoetryDeps x.dependencies)
		poetry.group;
in

rec {
	dependencies = dependenciesByGroup // {
		run = fromPoetryDeps (builtins.removeAttrs poetry.dependencies ["python"]);
	};

	memtree = buildPythonApplication {
		pname = poetry.name;
		pyproject = true;
		inherit (pyproject.tool.poetry) version;

		nativeBuildInputs = with python3Packages; [
			poetry-core
		];

		propagatedBuildInputs = dependencies.run;

		src = with lib.fileset;
			toSource {
				root = ../.;
				fileset = unions [
					../pyproject.toml
					../memtree
					../tests
				];
			};

		# No need to run lints and tests twice each in each CI run.
		doCheck = false;

		pythonImportChecks = [ "memtree" ];
	};
}
