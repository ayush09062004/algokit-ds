"""Pythonic wrapper around std::unordered_map.

    from algokit_ds import unordered_map

    m = unordered_map(int, int)
    m[1] = 2
"""

from ._base import MapWrapper, resolve
from ._swig import unordered_map as _swig

_TYPES = {
    (int, int): _swig.IntIntUnorderedMap,
    (int, float): _swig.IntDoubleUnorderedMap,
    (str, int): _swig.StrIntUnorderedMap,
    (str, str): _swig.StrStrUnorderedMap,
}


class UnorderedMap(MapWrapper):
    __slots__ = ()


def unordered_map(key_type, value_type, *args):
    cls = resolve(_TYPES, (key_type, value_type), "unordered_map")
    return UnorderedMap(cls(*args))
