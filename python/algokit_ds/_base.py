"""Shared building blocks for the public algokit_ds containers.

Every container in this package is a thin wrapper around a SWIG-generated
C++ STL proxy object (e.g. ``_swig.vector.IntVector``). The wrapper exists
for three reasons only:

1. keep the raw SWIG proxy class out of the public API surface
   (repr, type name, isinstance checks all show a clean algokit_ds type)
2. normalize the handful of method names that differ between STL
   containers (insert / add / append)
3. resolve a Python type (or tuple of types, for maps) to the correct
   SWIG-generated class through a single, explicit lookup table per
   container -- this is the one place you touch to add a new type.

It deliberately does *not* reimplement anything the SWIG proxy already
does well: push_back/pop_back/append/pop/indexing/iteration on
vector/deque/set/map are already provided by SWIG's python typemaps and
are simply delegated to via ``__getattr__``.
"""

from __future__ import annotations

from typing import Any


def _type_label(key: Any) -> str:
    if isinstance(key, tuple):
        return ", ".join(t.__name__ for t in key)
    return getattr(key, "__name__", repr(key))


def resolve(type_map: dict, key: Any, container_name: str):
    """Look up the SWIG class registered for `key` in `type_map`.

    Raises a clear TypeError listing supported types instead of a bare
    KeyError, so users see exactly what to fix.
    """
    try:
        return type_map[key]
    except KeyError:
        if isinstance(key, tuple):
            entries = sorted(f"({_type_label(k)})" for k in type_map)
        else:
            entries = sorted(_type_label(k) for k in type_map)
        raise TypeError(
            f"{container_name}<{_type_label(key)}> is not supported. "
            f"Supported types: {', '.join(entries)}"
        ) from None


class Wrapper:
    """Base class: delegates unknown attributes to the wrapped SWIG object.

    Subclasses opt into the Python protocols (__len__, __iter__,
    __contains__, __getitem__, ...) that make sense for their container --
    std::stack and std::queue, for example, support neither iteration nor
    indexing in real C++, and this wrapper preserves that honestly instead
    of faking it.
    """

    __slots__ = ("_impl",)

    def __init__(self, impl):
        self._impl = impl

    def __getattr__(self, name):
        # Only called when normal attribute lookup fails, i.e. for
        # anything not explicitly defined on the wrapper: push_back,
        # front, back, size, empty, insert, clear, ...
        return getattr(self._impl, name)

    def __repr__(self):
        return f"{type(self).__name__}({self._impl!r})"


class SizedWrapper(Wrapper):
    """Adds len()/iteration/membership/equality for containers whose
    underlying SWIG proxy already supports them (vector, deque, set,
    multiset, unordered_set, unordered_multiset, map, multimap,
    unordered_map)."""

    __slots__ = ()

    def __len__(self):
        return len(self._impl)

    def __iter__(self):
        return iter(self._impl)

    def __contains__(self, item):
        return item in self._impl

    def __eq__(self, other):
        if isinstance(other, SizedWrapper):
            return list(self._impl) == list(other._impl)
        return NotImplemented

    def __repr__(self):
        return f"{type(self).__name__}({list(self._impl)!r})"


class SetWrapper(SizedWrapper):
    """set / multiset / unordered_set / unordered_multiset all differ in
    which of insert/add/append SWIG exposes; `.append()` happens to be
    generated for all four, so `.add()` normalizes on top of it."""

    __slots__ = ()

    def add(self, value):
        self._impl.append(value)


class MapWrapper(SizedWrapper):
    """map / multimap / unordered_map. SWIG's python typemaps already give
    the underlying object dict-style keys()/values()/items()/__contains__,
    this only adds subscript syntax (m[k], m[k] = v)."""

    __slots__ = ()

    def __getitem__(self, key):
        return self._impl[key]

    def __setitem__(self, key, value):
        self._impl[key] = value
