"""Maps each concrete SWIG container proxy class to the C++-backed
algorithm entry points generated for it in swig/algorithms.i.

This is the one place that knows how a container type (e.g.
``algokit_ds._swig.vector.IntVector``) maps onto the generated function
name (e.g. ``sort_IntVector``). Everything in _algorithms.py goes through
`swig_function()` here instead of hardcoding that mapping itself.

Extending this for a *new algorithm* on the containers already listed
requires no changes here at all -- `swig_function()` builds the name from
the container's suffix automatically. It only needs a new entry when a
*new container/type combination* gains algorithm support: add the
corresponding %template block to swig/algorithms.i, then add one line to
_CONTAINER_SUFFIXES below.
"""

from __future__ import annotations

from .._swig import algorithms as _swig
from .._swig import deque as _deque_swig
from .._swig import vector as _vector_swig
from ..deque import deque as _deque_factory
from ..vector import vector as _vector_factory

# Every container/type combination algorithms.i has been %template'd for,
# keyed by the concrete SWIG proxy class (not the Python-facing wrapper
# class -- Vector/Deque themselves never appear here, see _algorithms.py).
_CONTAINER_SUFFIXES = {
    _vector_swig.IntVector: "IntVector",
    _vector_swig.DoubleVector: "DoubleVector",
    _vector_swig.StrVector: "StrVector",
    _deque_swig.IntDeque: "IntDeque",
    _deque_swig.DoubleDeque: "DoubleDeque",
    _deque_swig.StrDeque: "StrDeque",
}

# How to rebuild a proper algokit_ds container from a given suffix. Used
# by algorithms that construct a brand new container (merge, set_union,
# unique_copy, rotate_copy, ...): SWIG converts a Container *returned by
# value* straight into a plain Python tuple (this is specific to
# by-value returns -- by-reference/pointer arguments, which is how
# sort()/reverse()/etc. mutate in place with zero copy, go through a
# different typemap and keep their proxy identity). So rather than
# re-wrapping a proxy object, this reconstructs a fresh Vector/Deque
# through the normal public factory, using the same container kind and
# element type the input had.
_FACTORY_BY_SUFFIX = {
    "IntVector": (_vector_factory, int),
    "DoubleVector": (_vector_factory, float),
    "StrVector": (_vector_factory, str),
    "IntDeque": (_deque_factory, int),
    "DoubleDeque": (_deque_factory, float),
    "StrDeque": (_deque_factory, str),
}

_SUPPORTED_LABEL = ", ".join(sorted(set(_CONTAINER_SUFFIXES.values())))


def suffix_of(impl) -> str | None:
    """The container/type suffix (e.g. "IntVector") for a raw SWIG
    object, or None if it isn't one of ours."""
    return _CONTAINER_SUFFIXES.get(type(impl))


def wrap_result(suffix: str, data):
    """Build a proper Vector/Deque of the given suffix's kind/element
    type from `data` (a plain Python sequence -- see the module
    docstring above for why it's a sequence and not a SWIG proxy).
    """
    factory, cpp_type = _FACTORY_BY_SUFFIX[suffix]
    return factory(cpp_type, list(data))


def swig_function(prefix: str, impl):
    """Look up the generated `<prefix>_<Suffix>` function for `impl`'s
    concrete SWIG type, e.g. swig_function("sort", an_IntVector) ->
    algorithms.sort_IntVector.

    Raises a clear TypeError (matching the style of algokit_ds._base's
    `resolve()`) rather than a bare AttributeError/KeyError.
    """
    suffix = suffix_of(impl)
    if suffix is None:
        raise TypeError(
            f"algokit_ds.algorithms.{prefix} does not support "
            f"{type(impl).__name__!r} containers. "
            f"Supported containers: {_SUPPORTED_LABEL}"
        )

    name = f"{prefix}_{suffix}"
    func = getattr(_swig, name, None)
    if func is None:
        raise TypeError(
            f"algokit_ds.algorithms.{prefix} is not implemented for "
            f"{suffix} yet."
        )
    return func


def require_same_type(prefix: str, a_impl, b_impl) -> None:
    """Binary algorithms (merge, set_union, swap_ranges, is_permutation,
    inner_product, ...) need both containers to be the exact same
    concrete container/type combination -- this gives a clear TypeError
    up front instead of a confusing error from deep inside SWIG's
    argument conversion when they don't match."""
    if type(a_impl) is not type(b_impl):
        a_suffix = suffix_of(a_impl) or type(a_impl).__name__
        b_suffix = suffix_of(b_impl) or type(b_impl).__name__
        raise TypeError(
            f"algokit_ds.algorithms.{prefix} requires both containers to be "
            f"the same type; got {a_suffix} and {b_suffix}"
        )
