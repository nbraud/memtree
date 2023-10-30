{ pkgs ? import <nixpkgs> {}}:
with pkgs;

let
	py = python3;
	drv = callPackage ./package.nix { python3Packages = py.pkgs; };
in
mkShell {
	nativeBuildInputs = [
		drv
		poetry
		py
	];
}
