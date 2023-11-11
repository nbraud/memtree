let
	lock = with builtins; fromJSON (readFile ./flake.lock);
	nixpkgs = with lock.nodes.nixpkgs.locked; builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
		sha256 = narHash;
	};
in
{ pkgs ? import nixpkgs { }}:

(import ./ci.nix { inherit pkgs; }).override (self: {
	nativeBuildInputs = with pkgs; self.nativeBuildInputs ++ [
		deadnix
		python3Packages.ipython
		pkgs.poetry
		yamllint
	];
})
