{ pkgs ? import <nixpkgs> {}}:
with pkgs;

let py = python39;
in
mkShell {
  nativeBuildInputs = [
    py
    notcurses
  ] ++ (with py.pkgs; [
    ipython
    rich
    setuptools
    wheel
  ]);
}
