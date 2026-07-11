"""Pythonic wrapper around std::stack.

    from algokit_ds import stack

    s = stack(int)
    s.push(1)
    s.top()
    s.pop()
    len(s)

Note: std::stack supports neither iteration nor indexing in C++, and this
wrapper preserves that honestly instead of faking a list-like interface.
"""

from ._base import Wrapper, resolve
from ._swig import stack as _swig

_TYPES = {
    int: _swig.IntStack,
    float: _swig.DoubleStack,
    str: _swig.StrStack,
}


class Stack(Wrapper):
    __slots__ = ()

    def __len__(self):
        return self._impl.size()

    def pop(self):
        # std::stack::pop() is void in real C++; return the removed
        # value so it behaves like list.pop() / Python idiom expects.
        value = self._impl.top()
        self._impl.pop()
        return value

    def __repr__(self):
        return f"{type(self).__name__}(size={self._impl.size()})"


def stack(cpp_type, *args):
    cls = resolve(_TYPES, cpp_type, "stack")
    return Stack(cls(*args))
