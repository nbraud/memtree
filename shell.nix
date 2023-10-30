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
	ciEnv = import ./ci.nix { inherit pkgs; };
	drv = callPackage ./package.nix { };
in
ciEnv.override (self: {
	nativeBuildInputs = self.nativeBuildInputs ++ [
		drv
		poetry
	];
})
