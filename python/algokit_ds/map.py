"""Pythonic wrapper around std::map.

    from algokit_ds import map

    m = map(int, int)
    m[1] = 2
    m.keys()
    m.values()
    m.items()

The key/value type pair is the dispatch key -- adding a new combination is
one line in _TYPES plus a matching %template(...) in swig/map.i.
"""

from ._base import MapWrapper, resolve
from ._swig import map as _swig

_TYPES = {
    (int, int): _swig.IntIntMap,
    (int, float): _swig.IntDoubleMap,
    (str, int): _swig.StrIntMap,
    (str, str): _swig.StrStrMap,
}


class Map(MapWrapper):
    __slots__ = ()


def map(key_type, value_type, *args):
    cls = resolve(_TYPES, (key_type, value_type), "map")
    return Map(cls(*args))
