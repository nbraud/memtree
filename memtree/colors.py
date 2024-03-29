import json
from functools import cache
from importlib import resources
from typing import Any, Callable, Sequence, Tuple, TypeVar
from warnings import warn

T = TypeVar("T", str, Sequence[str])
Palette = Callable[[float], str]
Vector = Tuple[float, float, float]


@cache
def turbo_data() -> Sequence[Vector]:
    def vector(v: Any) -> Vector:  # noqa: ANN401
        if not isinstance(v, Sequence):
            raise TypeError("Expected a sequence", v)
        if not len(v) == len(Vector.__args__):
            raise ValueError("Expected a 3-elements sequence")
        x, y, z = v
        if not all(isinstance(t, float) for t in (x, y, z)):
            raise TypeError("Expected floats")
        return (x, y, z)

    with resources.files(__package__).joinpath("data/turbo.json").open() as f:
        return tuple(vector(v) for v in json.load(f))


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
    c = (
        colormap[a][0] + (colormap[b][0] - colormap[a][0]) * f,
        colormap[a][1] + (colormap[b][1] - colormap[a][1]) * f,
        colormap[a][2] + (colormap[b][2] - colormap[a][2]) * f,
    )
    r, g, b = tuple(int(255 * y) for y in c)
    return f"rgb({r},{g},{b})"


def fixed_palette(*p: str) -> Palette:
    n = len(p)
    return clip(lambda x: p[min(n - 1, int(n * x))])


sixteen = fixed_palette("blue", "cyan", "green", "yellow", "red", "magenta")


ansi_cyan = fixed_palette(
    "green1",
    "spring_green2",
    "spring_green1",
    "medium_spring_green",
    "cyan2",
    "cyan1",
)


def default_palette() -> Palette:
    from rich.console import ColorSystem, Console

    match Console().color_system:
        case ColorSystem.TRUECOLOR:
            return turbo
        case ColorSystem.STANDARD:
            return ansi_cyan
        case _:
            return sixteen
