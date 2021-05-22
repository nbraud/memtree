{ pkgs ? import <nixpkgs> {}}:
with pkgs;

let py = python39;
in
mkShell {
  nativeBuildInputs = [ py ] ++ (with py.pkgs; [
    ipython
    rich
  ]);
}
