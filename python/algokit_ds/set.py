"""Pythonic wrapper around std::set.

    from algokit_ds import set

    s = set(int)
    s.add(1)
    1 in s
    len(s)
"""

from ._base import SetWrapper, resolve
from ._swig import set as _swig

_TYPES = {
    int: _swig.IntSet,
    float: _swig.DoubleSet,
    str: _swig.StrSet,
}


class Set(SetWrapper):
    __slots__ = ()


def set(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "set")
    return Set(cls(*args))
