import pytest
from hypothesis import given, note, strategies as st

from memtree import MemoryAmount


@pytest.mark.parametrize(
    "multiplier, prefix",
    ((1024 ** e, s) for (e, s) in enumerate(MemoryAmount.IEC_PREFIXES)),
)
@given(i=st.integers(1, 1023), f=st.floats(0, 1, exclude_max=True))
def test_any_value(multiplier: int, prefix: str, i: int, f: float):
    n = MemoryAmount(multiplier * i + int(f * multiplier))
    note("n = {n!r} B")
    assert str(n) == f"{i + 1 if f > 0.5 and multiplier > 1 else i} {prefix}B"


MAX_PREFIX = MemoryAmount.IEC_PREFIXES[-1]
MAX_MULTIPLIER = 1024 ** (len(MemoryAmount.IEC_PREFIXES) - 1)


@given(i=st.integers(1), j=st.integers(0, MAX_MULTIPLIER - 1))
def test_largest_values(i: int, j: int):
    n = MemoryAmount(MAX_MULTIPLIER * i + j)
    assert str(n) == f"{i if j < MAX_MULTIPLIER / 2 else i + 1} {MAX_PREFIX}B"
