let
	lock = with builtins; fromJSON (readFile ../flake.lock);
	nixpkgs = with lock.nodes.nixpkgs.locked; builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
		sha256 = narHash;
	};
in

{ pkgs ? import nixpkgs { } }:
{ groups ? []
, extras ? []
, name ? "env"
, text ? null
}:

let
	inherit (pkgs) lib mkShell writeShellApplication python3;
	inherit (pkgs.callPackage ./package.nix { }) dependencies;

	_name = "memtree-${name}";
in

with lib;
makeOverridable (args: with args;
	let
		name = _name;  # Silly workaround for let-bindings always being recursive
		union = groups: pyPkgs: concatMap (f: f pyPkgs) groups;
		inputs = optional (groups != []) (pipe dependencies [
			(attrVals groups)
			union
			python3.withPackages
		]) ++ extras;
	in
	if text == null
	then mkShell {
		inherit name;
		nativeBuildInputs = inputs;
	}
	else writeShellApplication {
		inherit name text;
		runtimeInputs = inputs;
	}
) { inherit groups extras text; }
