{ pkgs ? import <nixpkgs> {}}:
with pkgs;

let py = python39;
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
