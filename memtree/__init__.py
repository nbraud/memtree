#!/usr/bin/env python3

from pathlib import Path
from platform import system
from typing import Callable, Optional

from rich.tree import Tree

from .colors import default_palette

assert system() == "Linux", f"{__name__} only works on Linux."

_STRIPPED_EXTS = frozenset(("scope", "service", "slice"))
_DEFAULT_NODE = Path("/sys/fs/cgroup/")


class MemoryAmount(int):
    IEC_PREFIXES = ("", "ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi")

    def __str__(self):
        i = min(len(self.IEC_PREFIXES) - 1, (self.bit_length() - 1) // 10)
        if i < 1:
            return f"{int(self)} B"

        j = 10 * i  # binary exponent for the unit we selected
        round = self >> j  # integer part of the result
        leftover = self & ((1 << j) - 1)  # number of leftover bytes
        assert self == (round << j) + leftover

        threshold = 1 << (j - 1)  # we round up above this many leftover bytes
        return f"{round + int(leftover >= threshold)} {self.IEC_PREFIXES[i]}B"


def demangle_name(name: str) -> str:
    if "." in name:
        prefix, ext = name.rsplit(sep=".", maxsplit=1)
        if ext in _STRIPPED_EXTS:
            return prefix

    return name


def tree(p: Path = _DEFAULT_NODE, *,
         color: Optional[Callable[[float], str]] = None,
         demangle_name: Callable[[str], str] = demangle_name) -> Tree:
    if color is None:
        color = default_palette()

    def mem(q: Path) -> Optional[MemoryAmount]:
        try:
            return MemoryAmount((q / "memory.current").read_text())
        except FileNotFoundError:
            return None

    def _tree(p: Path) -> Tree:
        m = mem(p)
        if m is None:
            t = Tree(f"{demangle_name(p.name)}")
        elif not total_mem:
            t = Tree(f"{demangle_name(p.name)}: {m}")
        else:
            t = Tree(
                f"{demangle_name(p.name)}: {m} ({100 * m/total_mem :.0f}%)",
                style=color(m / total_mem),
            )

        children = sorted(
            (q for q in p.iterdir() if q.is_dir() and mem(q) != 0),
            key=mem,
            reverse=True,
        )
        for q in children:
            t.add(_tree(q))

        return t

    total_mem = mem(p) or sum(
        mem(cgroup)
        for cgroup in p.iterdir()
        if cgroup.is_dir()
    )
    return _tree(p)
