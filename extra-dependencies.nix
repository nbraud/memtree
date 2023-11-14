# Dev. dependencies which aren't yet in nixpkgs
{ fetchFromGitHub, python3Packages }:
let
  inherit (python3Packages) buildPythonPackage;
in

{
	flake8-commas = buildPythonPackage rec {
		pname = "flake8-commas";
		version = "2.1.0";

		src = fetchFromGitHub {
			owner = "PyCQA";
			repo = pname;
			rev = version;
			hash = "sha256-FX4EfKjEmu70rZLGRdAqp77ucWHd1+OcpCYozaC1qqQ=";
		};

		doCheck = false;  # TODO: fix test run
	};

	flake8-pyproject = buildPythonPackage rec {
		pname = "flake8-pyproject";
		version = "1.2.3";
		pyproject = true;

		src = fetchFromGitHub {
			owner = "john-hen";
			repo  = "Flake8-pyproject";
			rev   = version;
			hash  = "sha256-bPRIj7tYmm6I9eo1ZjiibmpVmGcHctZSuTvnKX+raPg=";
		};

		nativeBuildInputs = with python3Packages; [
			flit-core
		];
		propagatedBuildInputs = with python3Packages; [
			flake8
		];
	};
}
