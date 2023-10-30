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
	drv = callPackage ./package.nix { };
	extraDependencies = callPackage ./extra-dependencies.nix { };

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
		python3
	] ++ devTools;
}
