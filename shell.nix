let
	lock = with builtins; fromJSON (readFile ./flake.lock);
	nixpkgs = with lock.nodes.nixpkgs.locked; builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
		sha256 = narHash;
	};
in
{ pkgs ? import nixpkgs { }}:

(import ./ci.nix {}).override (self: {
	nativeBuildInputs = with pkgs; self.nativeBuildInputs ++ [
		pkgs.poetry
	];
})
