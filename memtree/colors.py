import json
from functools import cache
from importlib import resources
from typing import Callable, Sequence, Tuple, TypeVar
from warnings import warn


@cache
def turbo_data() -> Sequence[Tuple[float, float, float]]:
    with resources.files(__package__).joinpath('data/turbo.json').open() as f:
        return tuple(map(tuple, json.load(f)))


T = TypeVar('T')


def clip(f: Callable[[float], T]) -> Callable[[float], T]:
    def g(x: float) -> T:
        if not 0 <= x <= 1:
            warn(f"{x!r} is not a normalised value, clipping", stacklevel=2)
            x = min(max(0, x), 1)
        return f(x)

    return g


@clip
def turbo(x: float) -> str:
    """The Turbo colormap

    Adapted from gist.github.com/mikhailov-work/ee72ba4191942acecc03fe6da94fc73f
    Licensed under Apache-2.0, copyright Google LLC.
    """

    # The look-up table contains 256 sRGB triplets
    colormap = turbo_data()

    a = int(255.0 * x)
    b = min(255, a + 1)
    f = 255.0 * x - a
    c = (colormap[a][0] + (colormap[b][0] - colormap[a][0]) * f,
         colormap[a][1] + (colormap[b][1] - colormap[a][1]) * f,
         colormap[a][2] + (colormap[b][2] - colormap[a][2]) * f)
    r, g, b = tuple(map(lambda y: int(255 * y), c))
    return f"rgb({r},{g},{b})"


def fixed_palette(p: Sequence[T]) -> Callable[[float], T]:
    n = len(p)
    return clip(lambda x: p[min(n - 1, int(n * x))])


sixteen = fixed_palette(("blue", "cyan", "green", "yellow", "red", "magenta"))


ansi_cyan = fixed_palette(("green1", "spring_green2", "spring_green1",
                           "medium_spring_green", "cyan2", "cyan1"))


def default_palette():
    from rich.console import ColorSystem, Console
    cs = Console()._detect_color_system()
    if cs == ColorSystem.TRUECOLOR:
        return turbo
    elif cs == ColorSystem.STANDARD:
        return ansi_cyan
    else:
        return sixteen
