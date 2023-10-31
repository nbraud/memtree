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
	pkg = callPackage ./package.nix { };
in
lib.makeOverridable mkShell {
	nativeBuildInputs = [
		python3
		python3Packages.poetry-core
	] ++ (with pkg; dependencies ++ dev-dependencies);
}
