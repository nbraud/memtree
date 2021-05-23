#!/usr/bin/env python3

from pathlib import Path
from platform import system
from typing import Callable, Optional

from psutil import virtual_memory
from rich.tree import Tree

from .colors import default_palette

assert system() == 'Linux', f"{__name__} only works on Linux."

_STRIPPED_EXTS = frozenset((
    "scope", "service", "slice"
))

class MemoryAmount(int):
    def __str__(self):
        for p in ('', 'ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi', 'Yi'):
            if self < 1024:
                break
            self /= 1024

        return f"{self:.0f} {p}B"

def tree(p: Path = Path('/sys/fs/cgroup/'), *, color: Optional[Callable[[float], str]] = None) -> Tree:
    if color is None:
        color = default_palette()

    def mem(q: Path) -> Optional[MemoryAmount]:
        try:
            return MemoryAmount((q / 'memory.current').read_text())
        except FileNotFoundError:
            return None

    def name(q: Path) -> str:
        if '.' in q.name:
            prefix, ext = q.name.rsplit(sep='.', maxsplit=1)
            if ext in _STRIPPED_EXTS:
                return prefix
            
        return q.name

    def _tree(p: Path) -> Tree:
        m = mem(p)
        if m is None:
            t = Tree(f"{name(p)}")
        else:
            t = Tree(f"{name(p)}: {m} ({100 * m/vm.total :.0f}%)", style=color(m / vm.used))

        children = sorted(
            ( q for q in p.iterdir() if q.is_dir() and mem(q) != 0 ),
            key = mem, reverse = True
        )
        for q in children:
            t.add(_tree(q))

        return t

    vm = virtual_memory()
    return _tree(p)
