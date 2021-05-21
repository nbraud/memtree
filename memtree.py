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
        for (i, p) in enumerate(('', 'ki', 'Mi', 'Gi', 'Ti')):
            if self < 1024**(i+1):
                break

        return f"{self / (1024**i):.0f} {p}B"

def total_memory() -> MemoryAmount:
    return MemoryAmount(sysconf('SC_PAGE_SIZE') * sysconf('SC_PHYS_PAGES'))

def tree(p: Path = Path('/sys/fs/cgroup/')) -> Tree:
    def mem(q: Path) -> MemoryAmount:
        return MemoryAmount((q / 'memory.current').read_text())

    def name(q: Path) -> str:
        if '.' in q.name:
            prefix, ext = q.name.rsplit(sep='.', maxsplit=1)
            if ext in STRIPPED_EXTS:
                return prefix
            
        return q.name

    def _tree(p: Path) -> Tree:
        # TODO: Avoid reading `q/memory.current` 3 times for each cgroup  >_>'
        if (p / 'memory.current').exists():
            t = Tree(f"{name(p)}: {mem(p)} ({100 * mem(p) / total :.0f}%)")
        else:
            t = Tree(f"{name(p)}")

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
