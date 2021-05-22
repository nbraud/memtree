#!/usr/bin/env python3

from functools import reduce
from os import sysconf
from pathlib import Path
from platform import system
from typing import Optional

from rich import print
from rich.tree import Tree

assert system() == 'Linux', f"{__name__} only works on Linux."

STRIPPED_EXTS = frozenset((
    "scope", "service", "slice"
))

class MemoryAmount(int):
    def __str__(self):
        for p in ('', 'ki', 'Mi', 'Gi', 'Ti'):
            if self < 1024:
                break
            self /= 1024

        return f"{self:.0f} {p}B"

def total_memory() -> MemoryAmount:
    return MemoryAmount(sysconf('SC_PAGE_SIZE') * sysconf('SC_PHYS_PAGES'))

def tree(p: Path = Path('/sys/fs/cgroup/')) -> Tree:
    def mem(q: Path) -> Optional[MemoryAmount]:
        try:
           return MemoryAmount((q / 'memory.current').read_text())
        except FileNotFoundError:
            return None

    def name(q: Path) -> str:
        if '.' in q.name:
            prefix, ext = q.name.rsplit(sep='.', maxsplit=1)
            if ext in STRIPPED_EXTS:
                return prefix
            
        return q.name

    def _tree(p: Path) -> Tree:
        m = mem(p)
        if m is None:
            t = Tree(f"{name(p)}")
        else:
            t = Tree(f"{name(p)}: {m} ({100 * m / total :.0f}%)")

        children = sorted(
            ( q for q in p.iterdir() if q.is_dir() and mem(q) != 0 ),
            key = mem, reverse = True
        )
        for q in children:
            t.add(_tree(q))

        return t

    total = total_memory()
    return _tree(p)


if __name__ == "__main__":
    print(tree())
