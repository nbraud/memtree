#!/usr/bin/env python3

from os import sysconf
from pathlib import Path
from typing import Optional

from rich import print
from rich.tree import Tree

STRIPPED_EXTS = frozenset((
    "scope", "service", "slice"
))

def tree(p: Path = Path('/sys/fs/cgroup/'), _total: Optional[int] = None) -> Tree:
    def mem(q: Path) -> int:
        return int((q / 'memory.current').read_text())

    def mtext(q: Path) -> str:
        m = mem(q)
        pr = ['', 'ki', 'Mi', 'Gi', 'Ti']
        for (i, p) in enumerate(pr):
            if m < 1024**(i+1):
                break

        return f"{m / (1024**i):.0f} {p}B"

    def name(q: Path) -> str:
        try:
            prefix, ext = q.name.rsplit(sep='.', maxsplit=1)
            return prefix if ext in STRIPPED_EXTS else q.name
            
        except ValueError:
            return q.name

    assert p.is_dir()
    if _total is None:
        _total = sysconf('SC_PAGE_SIZE') * sysconf('SC_PHYS_PAGES')

    # TODO: Avoid reading `q/memory.current` 3 times for each cgroup  >_>'
    children = [ q for q in p.iterdir() if q.is_dir() and mem(q) != 0 ]
    children.sort(key = mem, reverse = True)

    if (p / 'memory.current').exists():
        t = Tree(f"{name(p)}: {mtext(p)} ({100 * mem(p) / _total :.0f}%)")
    else:
        t = Tree(f"{name(p)}")

    for q in children:
        t.add(tree(q, _total))

    return t


if __name__ == "__main__":
    print(tree())
