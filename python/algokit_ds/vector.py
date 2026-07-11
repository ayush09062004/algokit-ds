"""Pythonic wrapper around std::vector.

    from algokit_ds import vector

    v = vector(int)
    v = vector(int, 10)
    v = vector(int, 10, 0)
    v = vector(int, [1, 2, 3])

    v.append(5)      # Pythonic alias
    v.push_back(6)    # STL name, also available
    v.pop()
    v.pop_back()
"""

from ._base import SizedWrapper, resolve
from ._swig import vector as _swig

# Registering a new element type is exactly this: one line here, plus a
# matching %template(...) instantiation in swig/vector.i.
_TYPES = {
    int: _swig.IntVector,
    float: _swig.DoubleVector,
    str: _swig.StrVector,
}


class Vector(SizedWrapper):
    __slots__ = ()

    def __getitem__(self, index):
        return self._impl[index]

    def __setitem__(self, index, value):
        self._impl[index] = value


def vector(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "vector")
    return Vector(cls(*args))
