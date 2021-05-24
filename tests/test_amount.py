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
