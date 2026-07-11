"""Pythonic wrapper around std::queue.

    from algokit_ds import queue

    q = queue(int)
    q.push(1)
    q.front()
    q.back()
    q.pop()
    len(q)

Note: std::queue supports neither iteration nor indexing in C++, and this
wrapper preserves that honestly instead of faking a list-like interface.
"""

from ._base import Wrapper, resolve
from ._swig import queue as _swig

_TYPES = {
    int: _swig.IntQueue,
    float: _swig.DoubleQueue,
    str: _swig.StrQueue,
}


class Queue(Wrapper):
    __slots__ = ()

    def __len__(self):
        return self._impl.size()

    def pop(self):
        # std::queue::pop() is void in real C++; return the removed
        # value so it behaves like list.pop(0) / Python idiom expects.
        value = self._impl.front()
        self._impl.pop()
        return value

    def __repr__(self):
        return f"{type(self).__name__}(size={self._impl.size()})"


def queue(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "queue")
    return Queue(cls(*args))
