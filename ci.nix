let
	lock = with builtins; fromJSON (readFile ./flake.lock);
	nixpkgs = with lock.nodes.nixpkgs.locked; builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
		sha256 = narHash;
	};
in
{ pkgs ? import nixpkgs { }}:
with pkgs;

let
	extraDependencies = callPackage ./extra-dependencies.nix { };

	depsAndTools = with lib; pipe ./pyproject.toml [
		readFile
		builtins.fromTOML
		(getAttrFromPath [ "tool" "poetry" ])
		(getAttrs [ "dependencies" "dev-dependencies" ])
		attrValues
		(map attrNames)
		flatten
		(remove "python")
		(names: attrVals names (extraDependencies // python3Packages))
	];

in
lib.makeOverridable mkShell {
	nativeBuildInputs = [
		python3
		python3Packages.poetry-core
	] ++ depsAndTools;
}
