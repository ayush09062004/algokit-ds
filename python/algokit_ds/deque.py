"""Pythonic wrapper around std::deque.

    from algokit_ds import deque

    d = deque(int)
    d = deque(int, [1, 2, 3])

    d.append(5)        # push_back alias
    d.appendleft(0)     # push_front alias
    d.pop()
    d.popleft()
"""

from ._base import SizedWrapper, resolve
from ._swig import deque as _swig

_TYPES = {
    int: _swig.IntDeque,
    float: _swig.DoubleDeque,
    str: _swig.StrDeque,
}


class Deque(SizedWrapper):
    __slots__ = ()

    def __getitem__(self, index):
        return self._impl[index]

    def __setitem__(self, index, value):
        self._impl[index] = value

    def appendleft(self, value):
        self._impl.push_front(value)

    def popleft(self):
        # pop_front() is void in real STL (like pop_back()); grab the
        # front value first so popleft() behaves like list.pop(0).
        value = self._impl.front()
        self._impl.pop_front()
        return value


def deque(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "deque")
    return Deque(cls(*args))
