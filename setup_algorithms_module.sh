#!/usr/bin/env bash
set -euo pipefail

echo "Creating directories..."
mkdir -p cpp/algorithms
mkdir -p python/algokit_ds/algorithms
mkdir -p tests

echo "Writing cpp/algorithms/algorithms.hpp"
cat > cpp/algorithms/algorithms.hpp << 'EOF'
#pragma once
// Thin, generic wrappers around <algorithm> so a single template body can
// be instantiated (via SWIG %template, see swig/algorithms.i) for every
// container/type combination we support -- currently std::vector<T> and
// std::deque<T> for T in {int, double, std::string}.
//
// These take the container BY REFERENCE and operate on its iterators
// directly. Combined with the fact that SWIG passes its wrapped
// std::vector<T>/std::deque<T> proxy objects by reference (not by
// value-copy) once they've been %template-instantiated as a class
// elsewhere, calling e.g. algokit::sort(v) from Python mutates the exact
// same C++ object `v` wraps -- no data is copied into a temporary Python
// list or a temporary container first.
//
// To add a new algorithm: add one function here (and, if you want to
// avoid implicit per-translation-unit instantiation, one explicit
// instantiation line per container/type in algorithms.cpp), then wrap it
// for each supported container with %template(...) in swig/algorithms.i,
// then register it in python/algokit_ds/algorithms/_algorithms.py.

#include <algorithm>
#include <iterator>

namespace algokit {

template <typename Container>
void sort(Container& c) {
    std::sort(c.begin(), c.end());
}

template <typename Container>
void stable_sort(Container& c) {
    std::stable_sort(c.begin(), c.end());
}

template <typename Container>
void reverse(Container& c) {
    std::reverse(c.begin(), c.end());
}

template <typename Container>
bool binary_search(const Container& c, const typename Container::value_type& value) {
    return std::binary_search(c.begin(), c.end(), value);
}

// Returns an index (distance from begin()), not an iterator -- iterators
// aren't a meaningful concept to expose to Python callers here.
template <typename Container>
typename Container::difference_type
lower_bound(const Container& c, const typename Container::value_type& value) {
    return std::distance(c.begin(), std::lower_bound(c.begin(), c.end(), value));
}

template <typename Container>
typename Container::difference_type
upper_bound(const Container& c, const typename Container::value_type& value) {
    return std::distance(c.begin(), std::upper_bound(c.begin(), c.end(), value));
}

} // namespace algokit
EOF

echo "Writing cpp/algorithms/algorithms.cpp"
cat > cpp/algorithms/algorithms.cpp << 'EOF'
// Explicit instantiations of the algokit:: algorithm templates for every
// container/type combination currently supported. This keeps the actual
// template bodies out of algorithms.hpp's callers (SWIG's generated
// wrap.cxx just declares + calls these, it doesn't need to re-instantiate
// them), and gives future contributors one obvious place to add a line
// when a new container/type combination gets support.

#include "algorithms.hpp"

#include <deque>
#include <string>
#include <vector>

namespace algokit {

#define ALGOKIT_INSTANTIATE(Container, T)                                    \
    template void sort(Container<T>&);                                      \
    template void stable_sort(Container<T>&);                               \
    template void reverse(Container<T>&);                                   \
    template bool binary_search(const Container<T>&, const T&);             \
    template Container<T>::difference_type lower_bound(const Container<T>&, const T&); \
    template Container<T>::difference_type upper_bound(const Container<T>&, const T&);

ALGOKIT_INSTANTIATE(std::vector, int)
ALGOKIT_INSTANTIATE(std::vector, double)
ALGOKIT_INSTANTIATE(std::vector, std::string)

ALGOKIT_INSTANTIATE(std::deque, int)
ALGOKIT_INSTANTIATE(std::deque, double)
ALGOKIT_INSTANTIATE(std::deque, std::string)

#undef ALGOKIT_INSTANTIATE

} // namespace algokit
EOF

echo "Writing swig/algorithms.i"
cat > swig/algorithms.i << 'EOF'
%module algorithms
%{
#include "algorithms.hpp"
%}

%include "std_string.i"
%include "std_vector.i"
%include "std_deque.i"

// Re-declare the exact same C++ types the vector/deque modules already
// wrap. This does NOT create a second incompatible type: SWIG's runtime
// type table is keyed by the actual C++ type signature (e.g.
// "std::vector<int> *") and shared globally across every SWIG module
// loaded in the same process, so a Vector's underlying object -- created
// by the separately-compiled `vector` module -- is still recognized here
// and passed by reference, not copied. (We avoid %import "vector.i" on
// purpose: SWIG's generated cross-module `import vector` statement is a
// bare top-level import that breaks once vector.py lives inside a
// package like algokit_ds._swig instead of being importable as a
// top-level module.)
%template(IntVector)    std::vector<int>;
%template(DoubleVector) std::vector<double>;
%template(StrVector)    std::vector<std::string>;

%template(IntDeque)    std::deque<int>;
%template(DoubleDeque) std::deque<double>;
%template(StrDeque)    std::deque<std::string>;

%include "algorithms.hpp"

// --- std::vector<T> -------------------------------------------------------
%template(sort_IntVector)             algokit::sort<std::vector<int>>;
%template(sort_DoubleVector)          algokit::sort<std::vector<double>>;
%template(sort_StrVector)             algokit::sort<std::vector<std::string>>;

%template(stable_sort_IntVector)      algokit::stable_sort<std::vector<int>>;
%template(stable_sort_DoubleVector)   algokit::stable_sort<std::vector<double>>;
%template(stable_sort_StrVector)      algokit::stable_sort<std::vector<std::string>>;

%template(reverse_IntVector)          algokit::reverse<std::vector<int>>;
%template(reverse_DoubleVector)       algokit::reverse<std::vector<double>>;
%template(reverse_StrVector)          algokit::reverse<std::vector<std::string>>;

%template(binary_search_IntVector)    algokit::binary_search<std::vector<int>>;
%template(binary_search_DoubleVector) algokit::binary_search<std::vector<double>>;
%template(binary_search_StrVector)    algokit::binary_search<std::vector<std::string>>;

%template(lower_bound_IntVector)      algokit::lower_bound<std::vector<int>>;
%template(lower_bound_DoubleVector)   algokit::lower_bound<std::vector<double>>;
%template(lower_bound_StrVector)      algokit::lower_bound<std::vector<std::string>>;

%template(upper_bound_IntVector)      algokit::upper_bound<std::vector<int>>;
%template(upper_bound_DoubleVector)   algokit::upper_bound<std::vector<double>>;
%template(upper_bound_StrVector)      algokit::upper_bound<std::vector<std::string>>;

// --- std::deque<T> ---------------------------------------------------------
%template(sort_IntDeque)              algokit::sort<std::deque<int>>;
%template(sort_DoubleDeque)           algokit::sort<std::deque<double>>;
%template(sort_StrDeque)              algokit::sort<std::deque<std::string>>;

%template(stable_sort_IntDeque)       algokit::stable_sort<std::deque<int>>;
%template(stable_sort_DoubleDeque)    algokit::stable_sort<std::deque<double>>;
%template(stable_sort_StrDeque)       algokit::stable_sort<std::deque<std::string>>;

%template(reverse_IntDeque)           algokit::reverse<std::deque<int>>;
%template(reverse_DoubleDeque)        algokit::reverse<std::deque<double>>;
%template(reverse_StrDeque)           algokit::reverse<std::deque<std::string>>;

%template(binary_search_IntDeque)     algokit::binary_search<std::deque<int>>;
%template(binary_search_DoubleDeque)  algokit::binary_search<std::deque<double>>;
%template(binary_search_StrDeque)     algokit::binary_search<std::deque<std::string>>;

%template(lower_bound_IntDeque)       algokit::lower_bound<std::deque<int>>;
%template(lower_bound_DoubleDeque)    algokit::lower_bound<std::deque<double>>;
%template(lower_bound_StrDeque)       algokit::lower_bound<std::deque<std::string>>;

%template(upper_bound_IntDeque)       algokit::upper_bound<std::deque<int>>;
%template(upper_bound_DoubleDeque)    algokit::upper_bound<std::deque<double>>;
%template(upper_bound_StrDeque)       algokit::upper_bound<std::deque<std::string>>;
EOF

echo "Writing python/algokit_ds/algorithms/__init__.py"
cat > python/algokit_ds/algorithms/__init__.py << 'EOF'
"""C++ STL algorithms operating in place on algokit_ds containers.

    from algokit_ds import vector
    from algokit_ds.algorithms import sort, binary_search

    v = vector(int, [5, 4, 2, 1, 3])
    sort(v)
    assert list(v) == [1, 2, 3, 4, 5]
    assert binary_search(v, 3)

Every function here dispatches to a real std::sort / std::stable_sort /
std::reverse / std::binary_search / std::lower_bound / std::upper_bound
call operating directly on the C++ container behind the wrapper -- no
data is copied into a Python list first.

Supported containers: vector, deque (of int, float, or str).

binary_search/lower_bound/upper_bound all require the container to
already be sorted in ascending order, same precondition as the
underlying C++ algorithms -- this module does not sort for you.
"""

from ._algorithms import (
    binary_search,
    lower_bound,
    reverse,
    sort,
    stable_sort,
    upper_bound,
)

__all__ = [
    "sort",
    "stable_sort",
    "reverse",
    "binary_search",
    "lower_bound",
    "upper_bound",
]
EOF

echo "Writing python/algokit_ds/algorithms/_algorithms.py"
cat > python/algokit_ds/algorithms/_algorithms.py << 'EOF'
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
EOF

echo "Writing python/algokit_ds/algorithms/_registry.py"
cat > python/algokit_ds/algorithms/_registry.py << 'EOF'
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
EOF

echo "Writing tests/test_algorithms.py"
cat > tests/test_algorithms.py << 'EOF'
import pytest

from algokit_ds import deque, stack, vector
from algokit_ds.algorithms import (
    binary_search,
    lower_bound,
    reverse,
    sort,
    stable_sort,
    upper_bound,
)


def test_sort_mutates_in_place_and_returns_none():
    v = vector(int, [5, 4, 2, 1, 3])
    result = sort(v)
    assert result is None
    assert list(v) == [1, 2, 3, 4, 5]


def test_sort_float_and_str():
    v = vector(float, [3.5, 1.1, 2.2])
    sort(v)
    assert list(v) == [1.1, 2.2, 3.5]

    sv = vector(str, ["banana", "apple", "cherry"])
    sort(sv)
    assert list(sv) == ["apple", "banana", "cherry"]


def test_sort_on_deque():
    d = deque(int, [5, 4, 2, 1, 3])
    sort(d)
    assert list(d) == [1, 2, 3, 4, 5]


def test_stable_sort_matches_sort_for_totally_ordered_data():
    v = vector(int, [5, 4, 2, 1, 3])
    stable_sort(v)
    assert list(v) == [1, 2, 3, 4, 5]


def test_reverse():
    v = vector(int, [1, 2, 3])
    reverse(v)
    assert list(v) == [3, 2, 1]


def test_binary_search():
    v = vector(int, [1, 2, 3, 4, 5])
    assert binary_search(v, 3) is True
    assert binary_search(v, 99) is False


def test_lower_bound_and_upper_bound():
    v = vector(int, [1, 2, 2, 2, 3, 5])
    assert lower_bound(v, 2) == 1
    assert upper_bound(v, 2) == 4
    # value not present: both bounds land on the same insertion point
    assert lower_bound(v, 4) == upper_bound(v, 4) == 5


def test_target_api_example_from_readme():
    v = vector(int, [5, 4, 2, 1, 3])
    sort(v)
    assert list(v) == [1, 2, 3, 4, 5]
    assert binary_search(v, 3)
    assert lower_bound(v, 3) == 2
    assert upper_bound(v, 3) == 3


def test_operates_on_the_same_object_no_copy():
    v = vector(int, [3, 1, 2])
    impl_id_before = id(v._impl)
    sort(v)
    assert id(v._impl) == impl_id_before
    assert list(v) == [1, 2, 3]


def test_unsupported_container_raises_type_error():
    s = stack(int)
    s.push(1)
    with pytest.raises(TypeError):
        sort(s)


def test_raw_swig_object_also_accepted_not_just_the_wrapper():
    v = vector(int, [3, 1, 2])
    sort(v._impl)  # unwrap manually -- _algorithms._unwrap() should no-op here
    assert list(v) == [1, 2, 3]
EOF

echo "Overwriting CMakeLists.txt"
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)
project(algokit_ds LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Speed up rebuilds within the same session/container if ccache is available.
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
endif()

find_package(SWIG 4.0 REQUIRED)
include(UseSWIG)

# Find the Python interpreter and the extension-module development target.
find_package(Python3 REQUIRED COMPONENTS Interpreter Development.Module)

# ---------------------------------------------------------------------------
# Generated Python package
# ---------------------------------------------------------------------------
set(SWIG_OUT_DIR ${CMAKE_SOURCE_DIR}/python/algokit_ds/_swig)

file(MAKE_DIRECTORY ${SWIG_OUT_DIR})
file(WRITE ${SWIG_OUT_DIR}/__init__.py "")

set(CMAKE_SWIG_OUTDIR ${SWIG_OUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${SWIG_OUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${SWIG_OUT_DIR})

include_directories(${Python3_INCLUDE_DIRS})

# ---------------------------------------------------------------------------
# SWIG interface files
# ---------------------------------------------------------------------------
set(ALGOKIT_MODULES
    vector
    deque
    stack
    queue
    set
    multiset
    unordered_set
    unordered_multiset
    map
    multimap
    unordered_map
    algorithms
)

# A tiny static "sink" target that exists only to own a precompiled header.
# Every module below reuses it via target_precompile_headers(... REUSE_FROM),
# so the STL headers common to all 11 SWIG modules (<vector>, <map>,
# <string>, ...) are parsed once instead of 11 times.
add_library(algokit_pch OBJECT ${CMAKE_SOURCE_DIR}/cmake/pch_dummy.cpp)
set_target_properties(algokit_pch PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(algokit_pch PRIVATE ${Python3_INCLUDE_DIRS})
target_precompile_headers(algokit_pch PRIVATE
    <vector>
    <deque>
    <stack>
    <queue>
    <set>
    <unordered_set>
    <map>
    <unordered_map>
    <string>
)

foreach(mod ${ALGOKIT_MODULES})
    set(interface_file ${CMAKE_SOURCE_DIR}/swig/${mod}.i)

    set_property(SOURCE ${interface_file} PROPERTY CPLUSPLUS ON)

    swig_add_library(${mod}
        TYPE MODULE
        LANGUAGE python
        SOURCES ${interface_file}
    )

    set_property(TARGET ${mod}
        PROPERTY SWIG_USE_TARGET_INCLUDE_DIRECTORIES TRUE
    )

    target_include_directories(${mod}
        PRIVATE
            ${Python3_INCLUDE_DIRS}
    )

    target_precompile_headers(${mod} REUSE_FROM algokit_pch)

    # Correct target for Python extension modules.
    target_link_libraries(${mod}
        PRIVATE
            Python3::Module
    )

    set_target_properties(${mod}
        PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${SWIG_OUT_DIR}
            RUNTIME_OUTPUT_DIRECTORY ${SWIG_OUT_DIR}
    )
endforeach()

# ---------------------------------------------------------------------------
# `algorithms` needs actual C++ source of its own (algorithms.cpp) and a
# header search path for algorithms.hpp -- every other module's logic
# lives entirely in STL headers, so this is additive rather than a change
# to the generic loop above.
# ---------------------------------------------------------------------------
target_sources(algorithms PRIVATE ${CMAKE_SOURCE_DIR}/cpp/algorithms/algorithms.cpp)
target_include_directories(algorithms PRIVATE ${CMAKE_SOURCE_DIR}/cpp/algorithms)
EOF

echo "Overwriting MANIFEST.in"
cat > MANIFEST.in << 'EOF'
include CMakeLists.txt
include README.md
include LICENSE

recursive-include swig *.i
recursive-include cmake *.cpp *.h *.hpp
recursive-include cpp *.cpp *.h *.hpp

graft python

global-exclude __pycache__
global-exclude *.py[cod]
EOF

echo ""
echo "Done. New/updated files:"
echo "  cpp/algorithms/algorithms.hpp"
echo "  cpp/algorithms/algorithms.cpp"
echo "  swig/algorithms.i"
echo "  python/algokit_ds/algorithms/__init__.py"
echo "  python/algokit_ds/algorithms/_algorithms.py"
echo "  python/algokit_ds/algorithms/_registry.py"
echo "  tests/test_algorithms.py"
echo "  CMakeLists.txt (overwritten)"
echo "  MANIFEST.in (overwritten)"
echo ""
echo "Next: rebuild and test with:"
echo "  rm -rf build dist *.egg-info python/algokit_ds.egg-info python/algokit_ds/_swig/*PYTHON_wrap.cxx python/algokit_ds/_swig/*.so python/algokit_ds/_swig/*.py"
echo "  pip uninstall -y algokit-ds"
echo "  pip install ."
echo "  pytest tests/ -v"