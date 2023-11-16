let
	lock = with builtins; fromJSON (readFile ./flake.lock);
	nixpkgs = with lock.nodes.nixpkgs.locked; builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
		sha256 = narHash;
	};
in
{ pkgs ? import nixpkgs { }}:

import ./.nix/env.nix { inherit pkgs; } {
	groups = [ "dev" "lint" "run" "test" ];
	extras = with pkgs; [
		deadnix
		python3Packages.ipython
		poetry
		yamllint
	];
}
