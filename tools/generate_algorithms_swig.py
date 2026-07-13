#!/usr/bin/env python3
"""Regenerates swig/algorithms.i from tools/algorithms_spec.py.

Usage:
    python3 tools/generate_algorithms_swig.py

The output is a plain, committed source file, same as every other .i
file in this repo -- this script is a development-time tool, not part of
the CMake build, so running it does not add any configure-time
dependency and does not affect install/build time at all. Run it after
editing algorithms_spec.py and commit the resulting diff.
"""

from __future__ import annotations

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from algorithms_spec import (  # noqa: E402
    ALGORITHMS,
    CONTAINER_TYPE_NAMES,
    PAIR_CONTAINER_RETURNING,
)

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
OUTPUT_PATH = REPO_ROOT / "swig" / "algorithms.i"

HEADER = """\
%module algorithms
%{
#include "algorithms.hpp"
%}

%include "exception.i"
%include "std_string.i"
%include "std_vector.i"
%include "std_deque.i"
%include "std_pair.i"

// Without this, an exception thrown from inside a wrapped function
// surfaces as an uncaught C++ exception, which calls std::terminate()
// and crashes the entire process instead of raising a normal Python
// exception. This applies to every wrapped function in the module.
//
// algokit::PythonError is caught *first* and specifically: it means a
// user-supplied predicate/generator callback itself raised, and CPython
// has already set that original exception (type, message, traceback) on
// the interpreter. SWIG_fail there returns NULL without calling
// PyErr_SetString again, so the user's own exception propagates
// unchanged -- it is not replaced by a generic RuntimeError.
%exception {
    try {
        $action
    } catch (const algokit::PythonError&) {
        SWIG_fail;
    } catch (const std::out_of_range& e) {
        SWIG_exception(SWIG_IndexError, e.what());
    } catch (const std::invalid_argument& e) {
        SWIG_exception(SWIG_ValueError, e.what());
    } catch (const std::exception& e) {
        SWIG_exception(SWIG_RuntimeError, e.what());
    }
}

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

// A single shared (index, index) pair type, reused by every algorithm
// that returns two positions (currently just minmax_element) regardless
// of which container/type it was called on -- these are plain longs, not
// container-typed, so there is exactly one of these for the whole module.
%template(LongPair) std::pair<long, long>;

// PyCallable (py_callback.hpp) is an internal implementation detail used
// to bridge predicate/generator callbacks back into Python. It is never
// used as a parameter type directly -- every function that needs a
// callback takes a plain PyObject* (which SWIG passes straight through
// natively, no typemap required) and constructs a PyCallable from it
// internally. %ignore just keeps SWIG from also generating a spurious
// wrapper class for PyCallable itself when it's pulled in transitively
// while parsing algorithms.hpp.
%ignore algokit::PyCallable;

%include "algorithms.hpp"

"""


def pair_container_template_name(suffix: str) -> str:
    return f"Pair{suffix}"


def generate() -> str:
    parts = [HEADER]

    # partition_copy needs std::pair<Container, Container> declared once
    # per container/type before it can itself be %template'd (the return
    # type must be a known SWIG type before the function that returns it
    # is wrapped).
    pair_algorithms = [name for name, *_ in ALGORITHMS if name in PAIR_CONTAINER_RETURNING]
    if pair_algorithms:
        parts.append("// --- pair-of-container return types ---\n")
        seen: set[str] = set()
        for name, containers, types in ALGORITHMS:
            if name not in PAIR_CONTAINER_RETURNING:
                continue
            for container in containers:
                for t in types:
                    cxx_type, suffix = CONTAINER_TYPE_NAMES[(container, t)]
                    if suffix in seen:
                        continue
                    seen.add(suffix)
                    parts.append(
                        f"%template({pair_container_template_name(suffix)}) "
                        f"std::pair<{cxx_type}, {cxx_type}>;\n"
                    )
        parts.append("\n")

    for name, containers, types in ALGORITHMS:
        parts.append(f"// --- {name} ---\n")
        for container in containers:
            for t in types:
                cxx_type, suffix = CONTAINER_TYPE_NAMES[(container, t)]
                parts.append(f"%template({name}_{suffix}) algokit::{name}<{cxx_type}>;\n")
        parts.append("\n")

    return "".join(parts)


def main() -> None:
    content = generate()
    OUTPUT_PATH.write_text(content)
    print(f"Wrote {OUTPUT_PATH} ({content.count(chr(10))} lines)")


if __name__ == "__main__":
    main()
