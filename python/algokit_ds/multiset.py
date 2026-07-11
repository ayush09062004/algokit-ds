"""Pythonic wrapper around std::multiset.

    from algokit_ds import multiset

    s = multiset(int)
    s.add(1)
    s.add(1)
    len(s)  # 2 -- duplicates allowed
"""

from ._base import SetWrapper, resolve
from ._swig import multiset as _swig

_TYPES = {
    int: _swig.IntMultiset,
    float: _swig.DoubleMultiset,
    str: _swig.StrMultiset,
}


class Multiset(SetWrapper):
    __slots__ = ()


def multiset(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "multiset")
    return Multiset(cls(*args))
