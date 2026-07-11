"""Pythonic wrapper around std::unordered_multiset.

    from algokit_ds import unordered_multiset

    s = unordered_multiset(int)
    s.add(1)
    s.add(1)
    len(s)  # 2 -- duplicates allowed
"""

from ._base import SetWrapper, resolve
from ._swig import unordered_multiset as _swig

_TYPES = {
    int: _swig.IntUnorderedMultiset,
    float: _swig.DoubleUnorderedMultiset,
    str: _swig.StrUnorderedMultiset,
}


class UnorderedMultiset(SetWrapper):
    __slots__ = ()


def unordered_multiset(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "unordered_multiset")
    return UnorderedMultiset(cls(*args))
