"""Pythonic wrapper around std::multimap.

    from algokit_ds import multimap

    m = multimap(int, int)
    m[1] = 2
"""

from ._base import MapWrapper, resolve
from ._swig import multimap as _swig

_TYPES = {
    (int, int): _swig.IntIntMultimap,
    (int, float): _swig.IntDoubleMultimap,
    (str, int): _swig.StrIntMultimap,
    (str, str): _swig.StrStrMultimap,
}


class Multimap(MapWrapper):
    __slots__ = ()


def multimap(key_type, value_type, *args):
    cls = resolve(_TYPES, (key_type, value_type), "multimap")
    return Multimap(cls(*args))
