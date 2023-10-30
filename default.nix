{ pkgs ? import <nixpkgs> {}}:
with pkgs;

let py = python3;
in
mkShell {
  nativeBuildInputs = [
    poetry
    py
  ] ++ (with py.pkgs; [
    ipython
    psutil
    rich
  ]);
}
