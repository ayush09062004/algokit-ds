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

_SUPPORTED_LABEL = ", ".join(sorted(set(_CONTAINER_SUFFIXES.values())))


def swig_function(prefix: str, impl):
    """Look up the generated `<prefix>_<Suffix>` function for `impl`'s
    concrete SWIG type, e.g. swig_function("sort", an_IntVector) ->
    algorithms.sort_IntVector.

    Raises a clear TypeError (matching the style of algokit_ds._base's
    `resolve()`) rather than a bare AttributeError/KeyError.
    """
    suffix = _CONTAINER_SUFFIXES.get(type(impl))
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
