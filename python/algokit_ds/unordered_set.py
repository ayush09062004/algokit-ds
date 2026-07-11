"""Pythonic wrapper around std::unordered_set.

    from algokit_ds import unordered_set

    s = unordered_set(int)
    s.add(1)
    1 in s
"""

from ._base import SetWrapper, resolve
from ._swig import unordered_set as _swig

_TYPES = {
    int: _swig.IntUnorderedSet,
    float: _swig.DoubleUnorderedSet,
    str: _swig.StrUnorderedSet,
}


class UnorderedSet(SetWrapper):
    __slots__ = ()


def unordered_set(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "unordered_set")
    return UnorderedSet(cls(*args))
