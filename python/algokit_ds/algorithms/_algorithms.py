"""Thin Python entry points over the C++ algorithms module.

Every function here does exactly three things: unwrap the algokit_ds
container wrapper (Vector/Deque/...) down to its underlying SWIG proxy
object, look up the matching generated function via `_registry`, and call
it. No data is copied into a Python list anywhere in this path -- the
generated function operates on the real C++ object behind the wrapper.
"""

from __future__ import annotations

from ._registry import swig_function


def _unwrap(container):
    # Accept either a public wrapper (Vector, Deque, ...) or a raw SWIG
    # proxy object directly, the same way algokit_ds._base.Wrapper
    # delegates unknown attributes straight to `_impl`.
    return getattr(container, "_impl", container)


def sort(container) -> None:
    """In-place std::sort. Mutates `container`; returns None, matching
    the convention of list.sort()."""
    impl = _unwrap(container)
    swig_function("sort", impl)(impl)


def stable_sort(container) -> None:
    """In-place std::stable_sort."""
    impl = _unwrap(container)
    swig_function("stable_sort", impl)(impl)


def reverse(container) -> None:
    """In-place std::reverse."""
    impl = _unwrap(container)
    swig_function("reverse", impl)(impl)


def binary_search(container, value) -> bool:
    """std::binary_search. `container` must already be sorted (ascending),
    same precondition as the C++ algorithm -- this does not check or sort
    for you."""
    impl = _unwrap(container)
    return swig_function("binary_search", impl)(impl, value)


def lower_bound(container, value) -> int:
    """std::lower_bound, returned as an index (distance from the start)
    rather than an iterator. `container` must already be sorted."""
    impl = _unwrap(container)
    return swig_function("lower_bound", impl)(impl, value)


def upper_bound(container, value) -> int:
    """std::upper_bound, returned as an index rather than an iterator.
    `container` must already be sorted."""
    impl = _unwrap(container)
    return swig_function("upper_bound", impl)(impl, value)
