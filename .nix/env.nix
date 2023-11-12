let
	lock = with builtins; fromJSON (readFile ../flake.lock);
	nixpkgs = with lock.nodes.nixpkgs.locked; builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
		sha256 = narHash;
	};
in

{ pkgs ? import nixpkgs { } }:
{ groups
, extras ? []
, text ? null
}:

let
	inherit (pkgs) lib mkShell writeShellApplication;
	inherit (pkgs.callPackage ./package.nix { }) dependencies;
in

lib.makeOverridable (args: with args;
	let
		inputs = with lib; pipe dependencies [
			(attrVals groups)
			flatten
		] ++ extras;
	in
	if text == null
	then mkShell {
		nativeBuildInputs = inputs;
	}
	else writeShellApplication {
		name = "memtree-env";  # TODO: individualize?
		runtimeInputs = inputs;
		inherit text;
	}
) { inherit groups extras text; }
