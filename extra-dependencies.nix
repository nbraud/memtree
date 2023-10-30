# Dev. dependencies which aren't yet in nixpkgs
{ lib
, fetchFromGitHub
, python3Packages
, ... }:

let
  inherit (python3Packages) buildPythonPackage;
in
{
	bork = buildPythonPackage rec {
		pname = "bork";
		version = "6.0.1";
		pyproject = true;

		propagatedBuildInputs = with python3Packages; [
			wheel
			build
			packaging
			pep517
			toml
			twine
			click
			coloredlogs
		];

		src = fetchFromGitHub {
			owner = "duckinator";
			repo = pname;
			rev = "v${version}";
			hash = "sha256-/NjO8XdmL0jsdrZvJzXmW2K/nWw/ukP5FDHinQZ+sdE=";
		};
	};

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
}
