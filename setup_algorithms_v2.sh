#!/usr/bin/env bash
set -euo pipefail

echo "Creating directories..."
mkdir -p cpp/algorithms
mkdir -p python/algokit_ds/algorithms
mkdir -p tools
mkdir -p tests
mkdir -p benchmarks

echo "Writing cpp/algorithms/algorithms.hpp"
cat > cpp/algorithms/algorithms.hpp << 'EOF'
#pragma once
// Thin, generic wrappers around <algorithm> and <numeric> so a single
// template body can be instantiated (via SWIG %template, see
// swig/algorithms.i, generated from tools/algorithms_spec.py) for every
// container/type combination we support -- std::vector<T> and
// std::deque<T> for T in {int, double, std::string} (iota is numeric-only
// since std::string has no operator++).
//
// These take the container BY REFERENCE (or const&) and operate on its
// iterators directly. Combined with the fact that SWIG passes its
// wrapped std::vector<T>/std::deque<T> proxy objects by reference (not by
// value-copy) once they've been %template-instantiated as a class
// elsewhere, calling e.g. algokit::sort(v) from Python mutates the exact
// same C++ object `v` wraps -- no data is copied into a temporary Python
// list or a temporary container first.
//
// Functions that need a predicate or generator take an algokit::PyCallable
// by value (see py_callback.hpp) -- a lightweight bridge back into
// Python, rather than a SWIG director.
//
// To add a new algorithm:
//   1. Add one function here.
//   2. Add one line to tools/algorithms_spec.py.
//   3. Run `python3 tools/generate_algorithms_swig.py` and commit the
//      swig/algorithms.i diff.
//   4. Add one entry to python/algokit_ds/algorithms/_algorithms.py.
//
// Note on explicit instantiation: algorithms.cpp explicitly instantiates
// only the original six algorithms (sort/stable_sort/reverse/
// binary_search/lower_bound/upper_bound), kept from v1.0.0 for zero
// behavioral change. Every algorithm added here relies on ordinary
// implicit instantiation, which happens exactly once per container/type
// combination inside the generated SWIG wrap.cxx regardless -- hand
// -maintaining ~250 additional explicit instantiation lines (getting
// every predicate/pair-returning signature exactly right) would be a
// much larger duplication and correctness liability than the marginal
// compile-caching benefit it buys.

#include <algorithm>
#include <numeric>
#include <random>
#include <stdexcept>
#include <utility>

#include "py_callback.hpp"

namespace algokit {

// ===========================================================================
// Original v1.0.0 algorithms (unchanged)
// ===========================================================================

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

// ===========================================================================
// Searching
// ===========================================================================

// Returns -1 (not a valid index) rather than c.end()'s distance when not
// found, so the Python layer can convert it to None -- a clearer "not
// found" signal than a magic index equal to len(container).
template <typename Container>
typename Container::difference_type
find(const Container& c, const typename Container::value_type& value) {
    auto it = std::find(c.begin(), c.end(), value);
    return it == c.end() ? static_cast<typename Container::difference_type>(-1)
                          : std::distance(c.begin(), it);
}

template <typename Container>
typename Container::difference_type
find_if(const Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    auto it = std::find_if(c.begin(), c.end(), [&pred](const typename Container::value_type& v) {
        return pred.test(v);
    });
    return it == c.end() ? static_cast<typename Container::difference_type>(-1)
                          : std::distance(c.begin(), it);
}

template <typename Container>
typename Container::difference_type
count(const Container& c, const typename Container::value_type& value) {
    return std::count(c.begin(), c.end(), value);
}

template <typename Container>
typename Container::difference_type
count_if(const Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    return std::count_if(c.begin(), c.end(), [&pred](const typename Container::value_type& v) {
        return pred.test(v);
    });
}

// ===========================================================================
// Min / max
// ===========================================================================

template <typename Container>
typename Container::difference_type
min_element(const Container& c) {
    if (c.empty()) {
        throw std::out_of_range("min_element: container is empty");
    }
    return std::distance(c.begin(), std::min_element(c.begin(), c.end()));
}

template <typename Container>
typename Container::difference_type
max_element(const Container& c) {
    if (c.empty()) {
        throw std::out_of_range("max_element: container is empty");
    }
    return std::distance(c.begin(), std::max_element(c.begin(), c.end()));
}

// A fixed std::pair<long, long> (not container-typed) so SWIG only ever
// needs to wrap one pair-of-index type for this, shared across every
// container/type combination.
template <typename Container>
std::pair<long, long> minmax_element(const Container& c) {
    if (c.empty()) {
        throw std::out_of_range("minmax_element: container is empty");
    }
    auto result = std::minmax_element(c.begin(), c.end());
    return {static_cast<long>(std::distance(c.begin(), result.first)),
            static_cast<long>(std::distance(c.begin(), result.second))};
}

// ===========================================================================
// Modification
// ===========================================================================

template <typename Container>
void replace(Container& c, const typename Container::value_type& old_value,
             const typename Container::value_type& new_value) {
    std::replace(c.begin(), c.end(), old_value, new_value);
}

template <typename Container>
void replace_if(Container& c, PyObject* pred_obj, const typename Container::value_type& new_value) {
    PyCallable pred(pred_obj);
    std::replace_if(
        c.begin(), c.end(),
        [&pred](const typename Container::value_type& v) { return pred.test(v); }, new_value);
}

// Full erase-remove idiom (std::remove + container::erase), not just
// std::remove alone -- so the container's length actually shrinks, which
// is what a Python caller means by "remove". Both calls are real STL,
// this isn't a hand-rolled reimplementation of the algorithm itself.
template <typename Container>
void remove(Container& c, const typename Container::value_type& value) {
    c.erase(std::remove(c.begin(), c.end(), value), c.end());
}

template <typename Container>
void remove_if(Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    c.erase(std::remove_if(c.begin(), c.end(),
                            [&pred](const typename Container::value_type& v) { return pred.test(v); }),
            c.end());
}

template <typename Container>
void unique(Container& c) {
    c.erase(std::unique(c.begin(), c.end()), c.end());
}

template <typename Container>
Container unique_copy(const Container& c) {
    Container result;
    std::unique_copy(c.begin(), c.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
void fill(Container& c, const typename Container::value_type& value) {
    std::fill(c.begin(), c.end(), value);
}

template <typename Container>
void fill_n(Container& c, typename Container::difference_type n,
            const typename Container::value_type& value) {
    if (n < 0 || static_cast<typename Container::size_type>(n) > c.size()) {
        throw std::out_of_range("fill_n: n is out of range for this container's size");
    }
    std::fill_n(c.begin(), n, value);
}

template <typename Container>
void generate(Container& c, PyObject* gen_obj) {
    PyCallable gen(gen_obj);
    std::generate(c.begin(), c.end(),
                  [&gen]() { return gen.template generate<typename Container::value_type>(); });
}

template <typename Container>
void generate_n(Container& c, typename Container::difference_type n, PyObject* gen_obj) {
    if (n < 0 || static_cast<typename Container::size_type>(n) > c.size()) {
        throw std::out_of_range("generate_n: n is out of range for this container's size");
    }
    PyCallable gen(gen_obj);
    std::generate_n(c.begin(), n,
                     [&gen]() { return gen.template generate<typename Container::value_type>(); });
}

// Only the overlapping prefix is swapped, matching std::swap_ranges'
// own contract (it assumes the second range is at least as long as the
// first).
template <typename Container>
void swap_ranges(Container& a, Container& b) {
    auto n = std::min(a.size(), b.size());
    std::swap_ranges(a.begin(), a.begin() + static_cast<typename Container::difference_type>(n), b.begin());
}

// ===========================================================================
// Reordering
// ===========================================================================

template <typename Container>
void rotate(Container& c, typename Container::difference_type n) {
    if (n < 0 || static_cast<typename Container::size_type>(n) > c.size()) {
        throw std::out_of_range("rotate: n is out of range for this container's size");
    }
    std::rotate(c.begin(), c.begin() + n, c.end());
}

template <typename Container>
Container rotate_copy(const Container& c, typename Container::difference_type n) {
    if (n < 0 || static_cast<typename Container::size_type>(n) > c.size()) {
        throw std::out_of_range("rotate_copy: n is out of range for this container's size");
    }
    Container result;
    std::rotate_copy(c.begin(), c.begin() + n, c.end(), std::back_inserter(result));
    return result;
}

// seed < 0 means "seed from std::random_device" (nondeterministic);
// seed >= 0 is used directly, for reproducible shuffles in tests.
template <typename Container>
void shuffle(Container& c, long seed) {
    if (seed < 0) {
        std::random_device rd;
        std::mt19937 gen(rd());
        std::shuffle(c.begin(), c.end(), gen);
    } else {
        std::mt19937 gen(static_cast<std::mt19937::result_type>(seed));
        std::shuffle(c.begin(), c.end(), gen);
    }
}

// ===========================================================================
// Partitioning
// ===========================================================================

template <typename Container>
typename Container::difference_type
partition(Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    auto it = std::partition(c.begin(), c.end(), [&pred](const typename Container::value_type& v) {
        return pred.test(v);
    });
    return std::distance(c.begin(), it);
}

template <typename Container>
typename Container::difference_type
stable_partition(Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    auto it = std::stable_partition(c.begin(), c.end(),
                                     [&pred](const typename Container::value_type& v) { return pred.test(v); });
    return std::distance(c.begin(), it);
}

template <typename Container>
std::pair<Container, Container> partition_copy(const Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    Container yes;
    Container no;
    std::partition_copy(c.begin(), c.end(), std::back_inserter(yes), std::back_inserter(no),
                         [&pred](const typename Container::value_type& v) { return pred.test(v); });
    return {std::move(yes), std::move(no)};
}

template <typename Container>
bool is_partitioned(const Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    return std::is_partitioned(c.begin(), c.end(),
                                [&pred](const typename Container::value_type& v) { return pred.test(v); });
}

template <typename Container>
typename Container::difference_type
partition_point(const Container& c, PyObject* pred_obj) {
    PyCallable pred(pred_obj);
    auto it = std::partition_point(c.begin(), c.end(),
                                    [&pred](const typename Container::value_type& v) { return pred.test(v); });
    return std::distance(c.begin(), it);
}

// ===========================================================================
// Merging (both ranges must already be sorted ascending, same as the STL
// precondition)
// ===========================================================================

template <typename Container>
Container merge(const Container& a, const Container& b) {
    Container result;
    std::merge(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
void inplace_merge(Container& c, typename Container::difference_type mid) {
    if (mid < 0 || static_cast<typename Container::size_type>(mid) > c.size()) {
        throw std::out_of_range("inplace_merge: mid is out of range for this container's size");
    }
    std::inplace_merge(c.begin(), c.begin() + mid, c.end());
}

// ===========================================================================
// Set algorithms (both ranges must already be sorted ascending)
// ===========================================================================

template <typename Container>
Container set_union(const Container& a, const Container& b) {
    Container result;
    std::set_union(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
Container set_intersection(const Container& a, const Container& b) {
    Container result;
    std::set_intersection(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
Container set_difference(const Container& a, const Container& b) {
    Container result;
    std::set_difference(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
Container set_symmetric_difference(const Container& a, const Container& b) {
    Container result;
    std::set_symmetric_difference(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
bool includes(const Container& a, const Container& b) {
    return std::includes(a.begin(), a.end(), b.begin(), b.end());
}

// ===========================================================================
// Heap
// ===========================================================================

template <typename Container>
void make_heap(Container& c) {
    std::make_heap(c.begin(), c.end());
}

// Matches std::push_heap's own contract: the new element must already be
// at the back of the container (c.append(x)) before calling this.
template <typename Container>
void push_heap(Container& c) {
    std::push_heap(c.begin(), c.end());
}

// Matches std::pop_heap's own contract: moves the max to the back but
// does not remove it -- callers pop it themselves afterward.
template <typename Container>
void pop_heap(Container& c) {
    std::pop_heap(c.begin(), c.end());
}

template <typename Container>
void sort_heap(Container& c) {
    std::sort_heap(c.begin(), c.end());
}

template <typename Container>
bool is_heap(const Container& c) {
    return std::is_heap(c.begin(), c.end());
}

template <typename Container>
typename Container::difference_type
is_heap_until(const Container& c) {
    return std::distance(c.begin(), std::is_heap_until(c.begin(), c.end()));
}

// ===========================================================================
// Permutation
// ===========================================================================

template <typename Container>
bool next_permutation(Container& c) {
    return std::next_permutation(c.begin(), c.end());
}

template <typename Container>
bool prev_permutation(Container& c) {
    return std::prev_permutation(c.begin(), c.end());
}

template <typename Container>
bool is_permutation(const Container& a, const Container& b) {
    return a.size() == b.size() && std::is_permutation(a.begin(), a.end(), b.begin());
}

// ===========================================================================
// Numeric (<numeric>)
// ===========================================================================

template <typename Container>
typename Container::value_type
accumulate(const Container& c, const typename Container::value_type& init) {
    return std::accumulate(c.begin(), c.end(), init);
}

template <typename Container>
Container adjacent_difference(const Container& c) {
    Container result;
    std::adjacent_difference(c.begin(), c.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
Container partial_sum(const Container& c) {
    Container result;
    std::partial_sum(c.begin(), c.end(), std::back_inserter(result));
    return result;
}

template <typename Container>
typename Container::value_type
inner_product(const Container& a, const Container& b, const typename Container::value_type& init) {
    return std::inner_product(a.begin(), a.end(), b.begin(), init);
}

// Numeric types only -- std::string has no operator++, so this is
// registered for int/double containers only (see tools/algorithms_spec.py).
template <typename Container>
void iota(Container& c, const typename Container::value_type& start_value) {
    std::iota(c.begin(), c.end(), start_value);
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
//
// Deliberately covers only the original v1.0.0 six -- see the note at
// the top of algorithms.hpp for why algorithms added afterward rely on
// implicit instantiation instead of being added here too.

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

echo "Writing cpp/algorithms/py_callback.hpp"
cat > cpp/algorithms/py_callback.hpp << 'EOF'
#pragma once
// Python.h must be the first include in any translation unit that uses
// it (CPython's own requirement, due to feature-test macros it defines).
#include <Python.h>

#include <exception>
#include <stdexcept>
#include <string>

// A minimal, low-overhead wrapper around a Python callable, used by every
// algorithm that needs a predicate (find_if, remove_if, partition, ...)
// or a generator (generate, generate_n).
//
// SWIG's "directors" feature could do this too, but directors generate a
// full virtual-dispatch C++ class per callback type -- built for
// overriding polymorphic classes, not for "call this one Python function
// per element". That's meaningfully more generated code and compile
// time for a job this small. Talking to the Python C API directly here
// keeps the generated code (and the compile cost) proportional to what
// we actually need.
//
// Every algorithm function that needs a callback takes a plain
// `PyObject*` parameter (which SWIG passes straight through natively --
// no custom typemap needed) and constructs a PyCallable from it locally.

namespace algokit {

// Thrown when the user's Python callable itself raised -- CPython has
// already set the real exception (type, message, traceback) on the
// interpreter at that point. The SWIG %exception handler in
// swig/algorithms.i catches this specifically and re-raises via
// SWIG_fail *without* calling PyErr_SetString again, so the user's
// original exception (a ValueError, a custom exception, whatever it was)
// propagates unchanged instead of being replaced by a generic
// RuntimeError.
class PythonError : public std::exception {
public:
    const char* what() const noexcept override {
        return "algokit_ds: the Python callable raised an exception";
    }
};

class PyCallable {
public:
    explicit PyCallable(PyObject* callable) : callable_(callable) {
        Py_XINCREF(callable_);
    }

    PyCallable(const PyCallable& other) : callable_(other.callable_) {
        Py_XINCREF(callable_);
    }

    PyCallable& operator=(const PyCallable&) = delete;

    ~PyCallable() { Py_XDECREF(callable_); }

    // Predicate call: T -> bool. Used by find_if, count_if, remove_if,
    // replace_if, partition*, is_partitioned, partition_point.
    template <typename T>
    bool test(const T& value) const {
        PyObject* arg = to_python(value);
        PyObject* result = PyObject_CallFunctionObjArgs(callable_, arg, nullptr);
        Py_DECREF(arg);
        if (!result) {
            throw PythonError();
        }
        int truthy = PyObject_IsTrue(result);
        Py_DECREF(result);
        if (truthy < 0) {
            throw PythonError();
        }
        return truthy != 0;
    }

    // Generator call: () -> T. Used by generate, generate_n.
    template <typename T>
    T generate() const {
        PyObject* result = PyObject_CallObject(callable_, nullptr);
        if (!result) {
            throw PythonError();
        }
        T value = from_python<T>(result);
        Py_DECREF(result);
        return value;
    }

private:
    PyObject* callable_;

    static PyObject* to_python(int v) { return PyLong_FromLong(v); }
    static PyObject* to_python(double v) { return PyFloat_FromDouble(v); }
    static PyObject* to_python(const std::string& v) {
        return PyUnicode_FromStringAndSize(v.data(), static_cast<Py_ssize_t>(v.size()));
    }

    template <typename T>
    static T from_python(PyObject* obj);
};

template <>
inline int PyCallable::from_python<int>(PyObject* obj) {
    long v = PyLong_AsLong(obj);
    if (v == -1 && PyErr_Occurred()) {
        throw PythonError();
    }
    return static_cast<int>(v);
}

template <>
inline double PyCallable::from_python<double>(PyObject* obj) {
    double v = PyFloat_AsDouble(obj);
    if (v == -1.0 && PyErr_Occurred()) {
        throw PythonError();
    }
    return v;
}

template <>
inline std::string PyCallable::from_python<std::string>(PyObject* obj) {
    Py_ssize_t len = 0;
    const char* buf = PyUnicode_AsUTF8AndSize(obj, &len);
    if (!buf) {
        throw PythonError();
    }
    return std::string(buf, static_cast<std::size_t>(len));
}

} // namespace algokit
EOF

echo "Writing swig/algorithms.i"
cat > swig/algorithms.i << 'EOF'
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

// --- pair-of-container return types ---
%template(PairIntVector) std::pair<std::vector<int>, std::vector<int>>;
%template(PairDoubleVector) std::pair<std::vector<double>, std::vector<double>>;
%template(PairStrVector) std::pair<std::vector<std::string>, std::vector<std::string>>;
%template(PairIntDeque) std::pair<std::deque<int>, std::deque<int>>;
%template(PairDoubleDeque) std::pair<std::deque<double>, std::deque<double>>;
%template(PairStrDeque) std::pair<std::deque<std::string>, std::deque<std::string>>;

// --- sort ---
%template(sort_IntVector) algokit::sort<std::vector<int>>;
%template(sort_DoubleVector) algokit::sort<std::vector<double>>;
%template(sort_StrVector) algokit::sort<std::vector<std::string>>;
%template(sort_IntDeque) algokit::sort<std::deque<int>>;
%template(sort_DoubleDeque) algokit::sort<std::deque<double>>;
%template(sort_StrDeque) algokit::sort<std::deque<std::string>>;

// --- stable_sort ---
%template(stable_sort_IntVector) algokit::stable_sort<std::vector<int>>;
%template(stable_sort_DoubleVector) algokit::stable_sort<std::vector<double>>;
%template(stable_sort_StrVector) algokit::stable_sort<std::vector<std::string>>;
%template(stable_sort_IntDeque) algokit::stable_sort<std::deque<int>>;
%template(stable_sort_DoubleDeque) algokit::stable_sort<std::deque<double>>;
%template(stable_sort_StrDeque) algokit::stable_sort<std::deque<std::string>>;

// --- reverse ---
%template(reverse_IntVector) algokit::reverse<std::vector<int>>;
%template(reverse_DoubleVector) algokit::reverse<std::vector<double>>;
%template(reverse_StrVector) algokit::reverse<std::vector<std::string>>;
%template(reverse_IntDeque) algokit::reverse<std::deque<int>>;
%template(reverse_DoubleDeque) algokit::reverse<std::deque<double>>;
%template(reverse_StrDeque) algokit::reverse<std::deque<std::string>>;

// --- binary_search ---
%template(binary_search_IntVector) algokit::binary_search<std::vector<int>>;
%template(binary_search_DoubleVector) algokit::binary_search<std::vector<double>>;
%template(binary_search_StrVector) algokit::binary_search<std::vector<std::string>>;
%template(binary_search_IntDeque) algokit::binary_search<std::deque<int>>;
%template(binary_search_DoubleDeque) algokit::binary_search<std::deque<double>>;
%template(binary_search_StrDeque) algokit::binary_search<std::deque<std::string>>;

// --- lower_bound ---
%template(lower_bound_IntVector) algokit::lower_bound<std::vector<int>>;
%template(lower_bound_DoubleVector) algokit::lower_bound<std::vector<double>>;
%template(lower_bound_StrVector) algokit::lower_bound<std::vector<std::string>>;
%template(lower_bound_IntDeque) algokit::lower_bound<std::deque<int>>;
%template(lower_bound_DoubleDeque) algokit::lower_bound<std::deque<double>>;
%template(lower_bound_StrDeque) algokit::lower_bound<std::deque<std::string>>;

// --- upper_bound ---
%template(upper_bound_IntVector) algokit::upper_bound<std::vector<int>>;
%template(upper_bound_DoubleVector) algokit::upper_bound<std::vector<double>>;
%template(upper_bound_StrVector) algokit::upper_bound<std::vector<std::string>>;
%template(upper_bound_IntDeque) algokit::upper_bound<std::deque<int>>;
%template(upper_bound_DoubleDeque) algokit::upper_bound<std::deque<double>>;
%template(upper_bound_StrDeque) algokit::upper_bound<std::deque<std::string>>;

// --- find ---
%template(find_IntVector) algokit::find<std::vector<int>>;
%template(find_DoubleVector) algokit::find<std::vector<double>>;
%template(find_StrVector) algokit::find<std::vector<std::string>>;
%template(find_IntDeque) algokit::find<std::deque<int>>;
%template(find_DoubleDeque) algokit::find<std::deque<double>>;
%template(find_StrDeque) algokit::find<std::deque<std::string>>;

// --- find_if ---
%template(find_if_IntVector) algokit::find_if<std::vector<int>>;
%template(find_if_DoubleVector) algokit::find_if<std::vector<double>>;
%template(find_if_StrVector) algokit::find_if<std::vector<std::string>>;
%template(find_if_IntDeque) algokit::find_if<std::deque<int>>;
%template(find_if_DoubleDeque) algokit::find_if<std::deque<double>>;
%template(find_if_StrDeque) algokit::find_if<std::deque<std::string>>;

// --- count ---
%template(count_IntVector) algokit::count<std::vector<int>>;
%template(count_DoubleVector) algokit::count<std::vector<double>>;
%template(count_StrVector) algokit::count<std::vector<std::string>>;
%template(count_IntDeque) algokit::count<std::deque<int>>;
%template(count_DoubleDeque) algokit::count<std::deque<double>>;
%template(count_StrDeque) algokit::count<std::deque<std::string>>;

// --- count_if ---
%template(count_if_IntVector) algokit::count_if<std::vector<int>>;
%template(count_if_DoubleVector) algokit::count_if<std::vector<double>>;
%template(count_if_StrVector) algokit::count_if<std::vector<std::string>>;
%template(count_if_IntDeque) algokit::count_if<std::deque<int>>;
%template(count_if_DoubleDeque) algokit::count_if<std::deque<double>>;
%template(count_if_StrDeque) algokit::count_if<std::deque<std::string>>;

// --- min_element ---
%template(min_element_IntVector) algokit::min_element<std::vector<int>>;
%template(min_element_DoubleVector) algokit::min_element<std::vector<double>>;
%template(min_element_StrVector) algokit::min_element<std::vector<std::string>>;
%template(min_element_IntDeque) algokit::min_element<std::deque<int>>;
%template(min_element_DoubleDeque) algokit::min_element<std::deque<double>>;
%template(min_element_StrDeque) algokit::min_element<std::deque<std::string>>;

// --- max_element ---
%template(max_element_IntVector) algokit::max_element<std::vector<int>>;
%template(max_element_DoubleVector) algokit::max_element<std::vector<double>>;
%template(max_element_StrVector) algokit::max_element<std::vector<std::string>>;
%template(max_element_IntDeque) algokit::max_element<std::deque<int>>;
%template(max_element_DoubleDeque) algokit::max_element<std::deque<double>>;
%template(max_element_StrDeque) algokit::max_element<std::deque<std::string>>;

// --- minmax_element ---
%template(minmax_element_IntVector) algokit::minmax_element<std::vector<int>>;
%template(minmax_element_DoubleVector) algokit::minmax_element<std::vector<double>>;
%template(minmax_element_StrVector) algokit::minmax_element<std::vector<std::string>>;
%template(minmax_element_IntDeque) algokit::minmax_element<std::deque<int>>;
%template(minmax_element_DoubleDeque) algokit::minmax_element<std::deque<double>>;
%template(minmax_element_StrDeque) algokit::minmax_element<std::deque<std::string>>;

// --- replace ---
%template(replace_IntVector) algokit::replace<std::vector<int>>;
%template(replace_DoubleVector) algokit::replace<std::vector<double>>;
%template(replace_StrVector) algokit::replace<std::vector<std::string>>;
%template(replace_IntDeque) algokit::replace<std::deque<int>>;
%template(replace_DoubleDeque) algokit::replace<std::deque<double>>;
%template(replace_StrDeque) algokit::replace<std::deque<std::string>>;

// --- replace_if ---
%template(replace_if_IntVector) algokit::replace_if<std::vector<int>>;
%template(replace_if_DoubleVector) algokit::replace_if<std::vector<double>>;
%template(replace_if_StrVector) algokit::replace_if<std::vector<std::string>>;
%template(replace_if_IntDeque) algokit::replace_if<std::deque<int>>;
%template(replace_if_DoubleDeque) algokit::replace_if<std::deque<double>>;
%template(replace_if_StrDeque) algokit::replace_if<std::deque<std::string>>;

// --- remove ---
%template(remove_IntVector) algokit::remove<std::vector<int>>;
%template(remove_DoubleVector) algokit::remove<std::vector<double>>;
%template(remove_StrVector) algokit::remove<std::vector<std::string>>;
%template(remove_IntDeque) algokit::remove<std::deque<int>>;
%template(remove_DoubleDeque) algokit::remove<std::deque<double>>;
%template(remove_StrDeque) algokit::remove<std::deque<std::string>>;

// --- remove_if ---
%template(remove_if_IntVector) algokit::remove_if<std::vector<int>>;
%template(remove_if_DoubleVector) algokit::remove_if<std::vector<double>>;
%template(remove_if_StrVector) algokit::remove_if<std::vector<std::string>>;
%template(remove_if_IntDeque) algokit::remove_if<std::deque<int>>;
%template(remove_if_DoubleDeque) algokit::remove_if<std::deque<double>>;
%template(remove_if_StrDeque) algokit::remove_if<std::deque<std::string>>;

// --- unique ---
%template(unique_IntVector) algokit::unique<std::vector<int>>;
%template(unique_DoubleVector) algokit::unique<std::vector<double>>;
%template(unique_StrVector) algokit::unique<std::vector<std::string>>;
%template(unique_IntDeque) algokit::unique<std::deque<int>>;
%template(unique_DoubleDeque) algokit::unique<std::deque<double>>;
%template(unique_StrDeque) algokit::unique<std::deque<std::string>>;

// --- unique_copy ---
%template(unique_copy_IntVector) algokit::unique_copy<std::vector<int>>;
%template(unique_copy_DoubleVector) algokit::unique_copy<std::vector<double>>;
%template(unique_copy_StrVector) algokit::unique_copy<std::vector<std::string>>;
%template(unique_copy_IntDeque) algokit::unique_copy<std::deque<int>>;
%template(unique_copy_DoubleDeque) algokit::unique_copy<std::deque<double>>;
%template(unique_copy_StrDeque) algokit::unique_copy<std::deque<std::string>>;

// --- fill ---
%template(fill_IntVector) algokit::fill<std::vector<int>>;
%template(fill_DoubleVector) algokit::fill<std::vector<double>>;
%template(fill_StrVector) algokit::fill<std::vector<std::string>>;
%template(fill_IntDeque) algokit::fill<std::deque<int>>;
%template(fill_DoubleDeque) algokit::fill<std::deque<double>>;
%template(fill_StrDeque) algokit::fill<std::deque<std::string>>;

// --- fill_n ---
%template(fill_n_IntVector) algokit::fill_n<std::vector<int>>;
%template(fill_n_DoubleVector) algokit::fill_n<std::vector<double>>;
%template(fill_n_StrVector) algokit::fill_n<std::vector<std::string>>;
%template(fill_n_IntDeque) algokit::fill_n<std::deque<int>>;
%template(fill_n_DoubleDeque) algokit::fill_n<std::deque<double>>;
%template(fill_n_StrDeque) algokit::fill_n<std::deque<std::string>>;

// --- generate ---
%template(generate_IntVector) algokit::generate<std::vector<int>>;
%template(generate_DoubleVector) algokit::generate<std::vector<double>>;
%template(generate_StrVector) algokit::generate<std::vector<std::string>>;
%template(generate_IntDeque) algokit::generate<std::deque<int>>;
%template(generate_DoubleDeque) algokit::generate<std::deque<double>>;
%template(generate_StrDeque) algokit::generate<std::deque<std::string>>;

// --- generate_n ---
%template(generate_n_IntVector) algokit::generate_n<std::vector<int>>;
%template(generate_n_DoubleVector) algokit::generate_n<std::vector<double>>;
%template(generate_n_StrVector) algokit::generate_n<std::vector<std::string>>;
%template(generate_n_IntDeque) algokit::generate_n<std::deque<int>>;
%template(generate_n_DoubleDeque) algokit::generate_n<std::deque<double>>;
%template(generate_n_StrDeque) algokit::generate_n<std::deque<std::string>>;

// --- swap_ranges ---
%template(swap_ranges_IntVector) algokit::swap_ranges<std::vector<int>>;
%template(swap_ranges_DoubleVector) algokit::swap_ranges<std::vector<double>>;
%template(swap_ranges_StrVector) algokit::swap_ranges<std::vector<std::string>>;
%template(swap_ranges_IntDeque) algokit::swap_ranges<std::deque<int>>;
%template(swap_ranges_DoubleDeque) algokit::swap_ranges<std::deque<double>>;
%template(swap_ranges_StrDeque) algokit::swap_ranges<std::deque<std::string>>;

// --- rotate ---
%template(rotate_IntVector) algokit::rotate<std::vector<int>>;
%template(rotate_DoubleVector) algokit::rotate<std::vector<double>>;
%template(rotate_StrVector) algokit::rotate<std::vector<std::string>>;
%template(rotate_IntDeque) algokit::rotate<std::deque<int>>;
%template(rotate_DoubleDeque) algokit::rotate<std::deque<double>>;
%template(rotate_StrDeque) algokit::rotate<std::deque<std::string>>;

// --- rotate_copy ---
%template(rotate_copy_IntVector) algokit::rotate_copy<std::vector<int>>;
%template(rotate_copy_DoubleVector) algokit::rotate_copy<std::vector<double>>;
%template(rotate_copy_StrVector) algokit::rotate_copy<std::vector<std::string>>;
%template(rotate_copy_IntDeque) algokit::rotate_copy<std::deque<int>>;
%template(rotate_copy_DoubleDeque) algokit::rotate_copy<std::deque<double>>;
%template(rotate_copy_StrDeque) algokit::rotate_copy<std::deque<std::string>>;

// --- shuffle ---
%template(shuffle_IntVector) algokit::shuffle<std::vector<int>>;
%template(shuffle_DoubleVector) algokit::shuffle<std::vector<double>>;
%template(shuffle_StrVector) algokit::shuffle<std::vector<std::string>>;
%template(shuffle_IntDeque) algokit::shuffle<std::deque<int>>;
%template(shuffle_DoubleDeque) algokit::shuffle<std::deque<double>>;
%template(shuffle_StrDeque) algokit::shuffle<std::deque<std::string>>;

// --- partition ---
%template(partition_IntVector) algokit::partition<std::vector<int>>;
%template(partition_DoubleVector) algokit::partition<std::vector<double>>;
%template(partition_StrVector) algokit::partition<std::vector<std::string>>;
%template(partition_IntDeque) algokit::partition<std::deque<int>>;
%template(partition_DoubleDeque) algokit::partition<std::deque<double>>;
%template(partition_StrDeque) algokit::partition<std::deque<std::string>>;

// --- stable_partition ---
%template(stable_partition_IntVector) algokit::stable_partition<std::vector<int>>;
%template(stable_partition_DoubleVector) algokit::stable_partition<std::vector<double>>;
%template(stable_partition_StrVector) algokit::stable_partition<std::vector<std::string>>;
%template(stable_partition_IntDeque) algokit::stable_partition<std::deque<int>>;
%template(stable_partition_DoubleDeque) algokit::stable_partition<std::deque<double>>;
%template(stable_partition_StrDeque) algokit::stable_partition<std::deque<std::string>>;

// --- partition_copy ---
%template(partition_copy_IntVector) algokit::partition_copy<std::vector<int>>;
%template(partition_copy_DoubleVector) algokit::partition_copy<std::vector<double>>;
%template(partition_copy_StrVector) algokit::partition_copy<std::vector<std::string>>;
%template(partition_copy_IntDeque) algokit::partition_copy<std::deque<int>>;
%template(partition_copy_DoubleDeque) algokit::partition_copy<std::deque<double>>;
%template(partition_copy_StrDeque) algokit::partition_copy<std::deque<std::string>>;

// --- is_partitioned ---
%template(is_partitioned_IntVector) algokit::is_partitioned<std::vector<int>>;
%template(is_partitioned_DoubleVector) algokit::is_partitioned<std::vector<double>>;
%template(is_partitioned_StrVector) algokit::is_partitioned<std::vector<std::string>>;
%template(is_partitioned_IntDeque) algokit::is_partitioned<std::deque<int>>;
%template(is_partitioned_DoubleDeque) algokit::is_partitioned<std::deque<double>>;
%template(is_partitioned_StrDeque) algokit::is_partitioned<std::deque<std::string>>;

// --- partition_point ---
%template(partition_point_IntVector) algokit::partition_point<std::vector<int>>;
%template(partition_point_DoubleVector) algokit::partition_point<std::vector<double>>;
%template(partition_point_StrVector) algokit::partition_point<std::vector<std::string>>;
%template(partition_point_IntDeque) algokit::partition_point<std::deque<int>>;
%template(partition_point_DoubleDeque) algokit::partition_point<std::deque<double>>;
%template(partition_point_StrDeque) algokit::partition_point<std::deque<std::string>>;

// --- merge ---
%template(merge_IntVector) algokit::merge<std::vector<int>>;
%template(merge_DoubleVector) algokit::merge<std::vector<double>>;
%template(merge_StrVector) algokit::merge<std::vector<std::string>>;
%template(merge_IntDeque) algokit::merge<std::deque<int>>;
%template(merge_DoubleDeque) algokit::merge<std::deque<double>>;
%template(merge_StrDeque) algokit::merge<std::deque<std::string>>;

// --- inplace_merge ---
%template(inplace_merge_IntVector) algokit::inplace_merge<std::vector<int>>;
%template(inplace_merge_DoubleVector) algokit::inplace_merge<std::vector<double>>;
%template(inplace_merge_StrVector) algokit::inplace_merge<std::vector<std::string>>;
%template(inplace_merge_IntDeque) algokit::inplace_merge<std::deque<int>>;
%template(inplace_merge_DoubleDeque) algokit::inplace_merge<std::deque<double>>;
%template(inplace_merge_StrDeque) algokit::inplace_merge<std::deque<std::string>>;

// --- set_union ---
%template(set_union_IntVector) algokit::set_union<std::vector<int>>;
%template(set_union_DoubleVector) algokit::set_union<std::vector<double>>;
%template(set_union_StrVector) algokit::set_union<std::vector<std::string>>;
%template(set_union_IntDeque) algokit::set_union<std::deque<int>>;
%template(set_union_DoubleDeque) algokit::set_union<std::deque<double>>;
%template(set_union_StrDeque) algokit::set_union<std::deque<std::string>>;

// --- set_intersection ---
%template(set_intersection_IntVector) algokit::set_intersection<std::vector<int>>;
%template(set_intersection_DoubleVector) algokit::set_intersection<std::vector<double>>;
%template(set_intersection_StrVector) algokit::set_intersection<std::vector<std::string>>;
%template(set_intersection_IntDeque) algokit::set_intersection<std::deque<int>>;
%template(set_intersection_DoubleDeque) algokit::set_intersection<std::deque<double>>;
%template(set_intersection_StrDeque) algokit::set_intersection<std::deque<std::string>>;

// --- set_difference ---
%template(set_difference_IntVector) algokit::set_difference<std::vector<int>>;
%template(set_difference_DoubleVector) algokit::set_difference<std::vector<double>>;
%template(set_difference_StrVector) algokit::set_difference<std::vector<std::string>>;
%template(set_difference_IntDeque) algokit::set_difference<std::deque<int>>;
%template(set_difference_DoubleDeque) algokit::set_difference<std::deque<double>>;
%template(set_difference_StrDeque) algokit::set_difference<std::deque<std::string>>;

// --- set_symmetric_difference ---
%template(set_symmetric_difference_IntVector) algokit::set_symmetric_difference<std::vector<int>>;
%template(set_symmetric_difference_DoubleVector) algokit::set_symmetric_difference<std::vector<double>>;
%template(set_symmetric_difference_StrVector) algokit::set_symmetric_difference<std::vector<std::string>>;
%template(set_symmetric_difference_IntDeque) algokit::set_symmetric_difference<std::deque<int>>;
%template(set_symmetric_difference_DoubleDeque) algokit::set_symmetric_difference<std::deque<double>>;
%template(set_symmetric_difference_StrDeque) algokit::set_symmetric_difference<std::deque<std::string>>;

// --- includes ---
%template(includes_IntVector) algokit::includes<std::vector<int>>;
%template(includes_DoubleVector) algokit::includes<std::vector<double>>;
%template(includes_StrVector) algokit::includes<std::vector<std::string>>;
%template(includes_IntDeque) algokit::includes<std::deque<int>>;
%template(includes_DoubleDeque) algokit::includes<std::deque<double>>;
%template(includes_StrDeque) algokit::includes<std::deque<std::string>>;

// --- make_heap ---
%template(make_heap_IntVector) algokit::make_heap<std::vector<int>>;
%template(make_heap_DoubleVector) algokit::make_heap<std::vector<double>>;
%template(make_heap_StrVector) algokit::make_heap<std::vector<std::string>>;
%template(make_heap_IntDeque) algokit::make_heap<std::deque<int>>;
%template(make_heap_DoubleDeque) algokit::make_heap<std::deque<double>>;
%template(make_heap_StrDeque) algokit::make_heap<std::deque<std::string>>;

// --- push_heap ---
%template(push_heap_IntVector) algokit::push_heap<std::vector<int>>;
%template(push_heap_DoubleVector) algokit::push_heap<std::vector<double>>;
%template(push_heap_StrVector) algokit::push_heap<std::vector<std::string>>;
%template(push_heap_IntDeque) algokit::push_heap<std::deque<int>>;
%template(push_heap_DoubleDeque) algokit::push_heap<std::deque<double>>;
%template(push_heap_StrDeque) algokit::push_heap<std::deque<std::string>>;

// --- pop_heap ---
%template(pop_heap_IntVector) algokit::pop_heap<std::vector<int>>;
%template(pop_heap_DoubleVector) algokit::pop_heap<std::vector<double>>;
%template(pop_heap_StrVector) algokit::pop_heap<std::vector<std::string>>;
%template(pop_heap_IntDeque) algokit::pop_heap<std::deque<int>>;
%template(pop_heap_DoubleDeque) algokit::pop_heap<std::deque<double>>;
%template(pop_heap_StrDeque) algokit::pop_heap<std::deque<std::string>>;

// --- sort_heap ---
%template(sort_heap_IntVector) algokit::sort_heap<std::vector<int>>;
%template(sort_heap_DoubleVector) algokit::sort_heap<std::vector<double>>;
%template(sort_heap_StrVector) algokit::sort_heap<std::vector<std::string>>;
%template(sort_heap_IntDeque) algokit::sort_heap<std::deque<int>>;
%template(sort_heap_DoubleDeque) algokit::sort_heap<std::deque<double>>;
%template(sort_heap_StrDeque) algokit::sort_heap<std::deque<std::string>>;

// --- is_heap ---
%template(is_heap_IntVector) algokit::is_heap<std::vector<int>>;
%template(is_heap_DoubleVector) algokit::is_heap<std::vector<double>>;
%template(is_heap_StrVector) algokit::is_heap<std::vector<std::string>>;
%template(is_heap_IntDeque) algokit::is_heap<std::deque<int>>;
%template(is_heap_DoubleDeque) algokit::is_heap<std::deque<double>>;
%template(is_heap_StrDeque) algokit::is_heap<std::deque<std::string>>;

// --- is_heap_until ---
%template(is_heap_until_IntVector) algokit::is_heap_until<std::vector<int>>;
%template(is_heap_until_DoubleVector) algokit::is_heap_until<std::vector<double>>;
%template(is_heap_until_StrVector) algokit::is_heap_until<std::vector<std::string>>;
%template(is_heap_until_IntDeque) algokit::is_heap_until<std::deque<int>>;
%template(is_heap_until_DoubleDeque) algokit::is_heap_until<std::deque<double>>;
%template(is_heap_until_StrDeque) algokit::is_heap_until<std::deque<std::string>>;

// --- next_permutation ---
%template(next_permutation_IntVector) algokit::next_permutation<std::vector<int>>;
%template(next_permutation_DoubleVector) algokit::next_permutation<std::vector<double>>;
%template(next_permutation_StrVector) algokit::next_permutation<std::vector<std::string>>;
%template(next_permutation_IntDeque) algokit::next_permutation<std::deque<int>>;
%template(next_permutation_DoubleDeque) algokit::next_permutation<std::deque<double>>;
%template(next_permutation_StrDeque) algokit::next_permutation<std::deque<std::string>>;

// --- prev_permutation ---
%template(prev_permutation_IntVector) algokit::prev_permutation<std::vector<int>>;
%template(prev_permutation_DoubleVector) algokit::prev_permutation<std::vector<double>>;
%template(prev_permutation_StrVector) algokit::prev_permutation<std::vector<std::string>>;
%template(prev_permutation_IntDeque) algokit::prev_permutation<std::deque<int>>;
%template(prev_permutation_DoubleDeque) algokit::prev_permutation<std::deque<double>>;
%template(prev_permutation_StrDeque) algokit::prev_permutation<std::deque<std::string>>;

// --- is_permutation ---
%template(is_permutation_IntVector) algokit::is_permutation<std::vector<int>>;
%template(is_permutation_DoubleVector) algokit::is_permutation<std::vector<double>>;
%template(is_permutation_StrVector) algokit::is_permutation<std::vector<std::string>>;
%template(is_permutation_IntDeque) algokit::is_permutation<std::deque<int>>;
%template(is_permutation_DoubleDeque) algokit::is_permutation<std::deque<double>>;
%template(is_permutation_StrDeque) algokit::is_permutation<std::deque<std::string>>;

// --- accumulate ---
%template(accumulate_IntVector) algokit::accumulate<std::vector<int>>;
%template(accumulate_DoubleVector) algokit::accumulate<std::vector<double>>;
%template(accumulate_StrVector) algokit::accumulate<std::vector<std::string>>;
%template(accumulate_IntDeque) algokit::accumulate<std::deque<int>>;
%template(accumulate_DoubleDeque) algokit::accumulate<std::deque<double>>;
%template(accumulate_StrDeque) algokit::accumulate<std::deque<std::string>>;

// --- adjacent_difference ---
%template(adjacent_difference_IntVector) algokit::adjacent_difference<std::vector<int>>;
%template(adjacent_difference_DoubleVector) algokit::adjacent_difference<std::vector<double>>;
%template(adjacent_difference_IntDeque) algokit::adjacent_difference<std::deque<int>>;
%template(adjacent_difference_DoubleDeque) algokit::adjacent_difference<std::deque<double>>;

// --- partial_sum ---
%template(partial_sum_IntVector) algokit::partial_sum<std::vector<int>>;
%template(partial_sum_DoubleVector) algokit::partial_sum<std::vector<double>>;
%template(partial_sum_StrVector) algokit::partial_sum<std::vector<std::string>>;
%template(partial_sum_IntDeque) algokit::partial_sum<std::deque<int>>;
%template(partial_sum_DoubleDeque) algokit::partial_sum<std::deque<double>>;
%template(partial_sum_StrDeque) algokit::partial_sum<std::deque<std::string>>;

// --- inner_product ---
%template(inner_product_IntVector) algokit::inner_product<std::vector<int>>;
%template(inner_product_DoubleVector) algokit::inner_product<std::vector<double>>;
%template(inner_product_IntDeque) algokit::inner_product<std::deque<int>>;
%template(inner_product_DoubleDeque) algokit::inner_product<std::deque<double>>;

// --- iota ---
%template(iota_IntVector) algokit::iota<std::vector<int>>;
%template(iota_DoubleVector) algokit::iota<std::vector<double>>;
%template(iota_IntDeque) algokit::iota<std::deque<int>>;
%template(iota_DoubleDeque) algokit::iota<std::deque<double>>;

EOF

echo "Writing tools/algorithms_spec.py"
cat > tools/algorithms_spec.py << 'EOF'
"""Declarative spec for every algorithm exposed by algokit_ds.algorithms.

Each entry in ALGORITHMS says which algokit::<name><Container> template to
instantiate, for which containers ("vector", "deque") and element types
("int", "double", "str"). That's genuinely all SWIG needs: %template
syntax doesn't encode a function's parameter list, only its template
parameter (the container type) -- the actual argument shapes (a value, a
predicate, a second container, ...) live entirely in
cpp/algorithms/algorithms.hpp and never need to be repeated here.

To add a new algorithm:
  1. Add one function to cpp/algorithms/algorithms.hpp.
  2. Add one line to ALGORITHMS below.
  3. Run `python3 tools/generate_algorithms_swig.py` and commit the
     resulting swig/algorithms.i diff.
  4. Add one entry to python/algokit_ds/algorithms/_algorithms.py.
"""

ALL_CONTAINERS = ("vector", "deque")
ALL_TYPES = ("int", "double", "str")
NUMERIC_TYPES = ("int", "double")

# (algorithm_name, containers, types)
ALGORITHMS = [
    # -- original v1.0.0 algorithms, regenerated here too so the whole
    #    file comes from one source of truth -------------------------------
    ("sort", ALL_CONTAINERS, ALL_TYPES),
    ("stable_sort", ALL_CONTAINERS, ALL_TYPES),
    ("reverse", ALL_CONTAINERS, ALL_TYPES),
    ("binary_search", ALL_CONTAINERS, ALL_TYPES),
    ("lower_bound", ALL_CONTAINERS, ALL_TYPES),
    ("upper_bound", ALL_CONTAINERS, ALL_TYPES),

    # -- searching ----------------------------------------------------------
    ("find", ALL_CONTAINERS, ALL_TYPES),
    ("find_if", ALL_CONTAINERS, ALL_TYPES),
    ("count", ALL_CONTAINERS, ALL_TYPES),
    ("count_if", ALL_CONTAINERS, ALL_TYPES),

    # -- min / max ------------------------------------------------------
    ("min_element", ALL_CONTAINERS, ALL_TYPES),
    ("max_element", ALL_CONTAINERS, ALL_TYPES),
    ("minmax_element", ALL_CONTAINERS, ALL_TYPES),

    # -- modification ---------------------------------------------------
    ("replace", ALL_CONTAINERS, ALL_TYPES),
    ("replace_if", ALL_CONTAINERS, ALL_TYPES),
    ("remove", ALL_CONTAINERS, ALL_TYPES),
    ("remove_if", ALL_CONTAINERS, ALL_TYPES),
    ("unique", ALL_CONTAINERS, ALL_TYPES),
    ("unique_copy", ALL_CONTAINERS, ALL_TYPES),
    ("fill", ALL_CONTAINERS, ALL_TYPES),
    ("fill_n", ALL_CONTAINERS, ALL_TYPES),
    ("generate", ALL_CONTAINERS, ALL_TYPES),
    ("generate_n", ALL_CONTAINERS, ALL_TYPES),
    ("swap_ranges", ALL_CONTAINERS, ALL_TYPES),

    # -- reordering -------------------------------------------------------
    ("rotate", ALL_CONTAINERS, ALL_TYPES),
    ("rotate_copy", ALL_CONTAINERS, ALL_TYPES),
    ("shuffle", ALL_CONTAINERS, ALL_TYPES),
    # random_shuffle intentionally omitted: removed from the standard in
    # C++20 and deprecated before that -- std::shuffle above is its
    # replacement and already covers the need.

    # -- partitioning -----------------------------------------------------
    ("partition", ALL_CONTAINERS, ALL_TYPES),
    ("stable_partition", ALL_CONTAINERS, ALL_TYPES),
    ("partition_copy", ALL_CONTAINERS, ALL_TYPES),
    ("is_partitioned", ALL_CONTAINERS, ALL_TYPES),
    ("partition_point", ALL_CONTAINERS, ALL_TYPES),

    # -- merging (ranges must already be sorted ascending) -----------------
    ("merge", ALL_CONTAINERS, ALL_TYPES),
    ("inplace_merge", ALL_CONTAINERS, ALL_TYPES),

    # -- set algorithms (ranges must already be sorted ascending) ----------
    ("set_union", ALL_CONTAINERS, ALL_TYPES),
    ("set_intersection", ALL_CONTAINERS, ALL_TYPES),
    ("set_difference", ALL_CONTAINERS, ALL_TYPES),
    ("set_symmetric_difference", ALL_CONTAINERS, ALL_TYPES),
    ("includes", ALL_CONTAINERS, ALL_TYPES),

    # -- heap ---------------------------------------------------------------
    ("make_heap", ALL_CONTAINERS, ALL_TYPES),
    ("push_heap", ALL_CONTAINERS, ALL_TYPES),
    ("pop_heap", ALL_CONTAINERS, ALL_TYPES),
    ("sort_heap", ALL_CONTAINERS, ALL_TYPES),
    ("is_heap", ALL_CONTAINERS, ALL_TYPES),
    ("is_heap_until", ALL_CONTAINERS, ALL_TYPES),

    # -- permutation --------------------------------------------------------
    ("next_permutation", ALL_CONTAINERS, ALL_TYPES),
    ("prev_permutation", ALL_CONTAINERS, ALL_TYPES),
    ("is_permutation", ALL_CONTAINERS, ALL_TYPES),

    # -- numeric (<numeric>) -------------------------------------------------
    ("accumulate", ALL_CONTAINERS, ALL_TYPES),
    ("adjacent_difference", ALL_CONTAINERS, NUMERIC_TYPES),  # needs operator-
    ("partial_sum", ALL_CONTAINERS, ALL_TYPES),
    ("inner_product", ALL_CONTAINERS, NUMERIC_TYPES),  # needs operator*
    ("iota", ALL_CONTAINERS, NUMERIC_TYPES),  # std::string has no operator++
]

# Algorithms whose C++ signature returns std::pair<Container, Container>
# instead of a scalar or a single Container -- these need one extra
# %template for the pair type itself before they can be wrapped.
PAIR_CONTAINER_RETURNING = {"partition_copy"}

CONTAINER_TYPE_NAMES = {
    ("vector", "int"): ("std::vector<int>", "IntVector"),
    ("vector", "double"): ("std::vector<double>", "DoubleVector"),
    ("vector", "str"): ("std::vector<std::string>", "StrVector"),
    ("deque", "int"): ("std::deque<int>", "IntDeque"),
    ("deque", "double"): ("std::deque<double>", "DoubleDeque"),
    ("deque", "str"): ("std::deque<std::string>", "StrDeque"),
}
EOF

echo "Writing tools/generate_algorithms_swig.py"
cat > tools/generate_algorithms_swig.py << 'EOF'
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

Every function here dispatches directly to a real std:: algorithm
operating on the C++ container behind the wrapper -- no data is copied
into a Python list first, and nothing here is reimplemented in Python.

Supported containers: vector, deque (of int, float, or str -- see each
function's docstring for numeric-only exceptions like iota).

Functions needing a predicate or generator (find_if, count_if, remove_if,
replace_if, partition*, generate*) take a plain Python callable, called
once per element directly from C++. If that callable raises, the
original exception (type, message, traceback) propagates unchanged.

Many algorithms here carry the same "already sorted" precondition as
real C++ (binary_search, lower_bound, upper_bound, merge, inplace_merge,
set_union, set_intersection, set_difference, set_symmetric_difference,
includes) -- this module does not sort for you and does not check.
"""

from ._algorithms import (
    accumulate,
    adjacent_difference,
    binary_search,
    count,
    count_if,
    find,
    find_if,
    fill,
    fill_n,
    generate,
    generate_n,
    includes,
    inner_product,
    inplace_merge,
    iota,
    is_heap,
    is_heap_until,
    is_partitioned,
    is_permutation,
    lower_bound,
    make_heap,
    max_element,
    merge,
    min_element,
    minmax_element,
    next_permutation,
    partial_sum,
    partition,
    partition_copy,
    partition_point,
    pop_heap,
    prev_permutation,
    push_heap,
    remove,
    remove_if,
    replace,
    replace_if,
    reverse,
    rotate,
    rotate_copy,
    set_difference,
    set_intersection,
    set_symmetric_difference,
    set_union,
    shuffle,
    sort,
    sort_heap,
    stable_partition,
    stable_sort,
    swap_ranges,
    unique,
    unique_copy,
    upper_bound,
)

__all__ = [
    "accumulate",
    "adjacent_difference",
    "binary_search",
    "count",
    "count_if",
    "find",
    "find_if",
    "fill",
    "fill_n",
    "generate",
    "generate_n",
    "includes",
    "inner_product",
    "inplace_merge",
    "iota",
    "is_heap",
    "is_heap_until",
    "is_partitioned",
    "is_permutation",
    "lower_bound",
    "make_heap",
    "max_element",
    "merge",
    "min_element",
    "minmax_element",
    "next_permutation",
    "partial_sum",
    "partition",
    "partition_copy",
    "partition_point",
    "pop_heap",
    "prev_permutation",
    "push_heap",
    "remove",
    "remove_if",
    "replace",
    "replace_if",
    "reverse",
    "rotate",
    "rotate_copy",
    "set_difference",
    "set_intersection",
    "set_symmetric_difference",
    "set_union",
    "shuffle",
    "sort",
    "sort_heap",
    "stable_partition",
    "stable_sort",
    "swap_ranges",
    "unique",
    "unique_copy",
    "upper_bound",
]
EOF

echo "Writing python/algokit_ds/algorithms/_algorithms.py"
cat > python/algokit_ds/algorithms/_algorithms.py << 'EOF'
"""Thin Python entry points over the C++ algorithms module.

Every function here does the same three things: unwrap the algokit_ds
container wrapper (Vector/Deque/...) down to its underlying SWIG proxy
object, look up the matching generated function via `_registry`, and call
it. No data is copied into a Python list anywhere in this path -- the
generated function operates on the real C++ object behind the wrapper.
Functions that build a brand new container (merge, unique_copy, ...) wrap
the SWIG result back into a proper Vector/Deque before returning it.

Preconditions inherited directly from the underlying STL algorithms are
not checked here beyond what SWIG/C++ itself checks (see each
docstring): binary_search/lower_bound/upper_bound/merge/set_* all require
their input(s) already sorted ascending, same as real C++.
"""

from __future__ import annotations

from ._registry import require_same_type, suffix_of, swig_function, wrap_result


def _unwrap(container):
    # Accept either a public wrapper (Vector, Deque, ...) or a raw SWIG
    # proxy object directly, the same way algokit_ds._base.Wrapper
    # delegates unknown attributes straight to `_impl`.
    return getattr(container, "_impl", container)


def _not_found_to_none(index: int):
    return None if index < 0 else index


# ===========================================================================
# Original v1.0.0 algorithms (unchanged)
# ===========================================================================


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
    """std::binary_search. `container` must already be sorted ascending."""
    impl = _unwrap(container)
    return swig_function("binary_search", impl)(impl, value)


def lower_bound(container, value) -> int:
    """std::lower_bound, returned as an index. `container` must already
    be sorted ascending."""
    impl = _unwrap(container)
    return swig_function("lower_bound", impl)(impl, value)


def upper_bound(container, value) -> int:
    """std::upper_bound, returned as an index. `container` must already
    be sorted ascending."""
    impl = _unwrap(container)
    return swig_function("upper_bound", impl)(impl, value)


# ===========================================================================
# Searching
# ===========================================================================


def find(container, value) -> int | None:
    """std::find. Returns the index of the first match, or None if not
    present (Pythonic; the C++ layer uses -1 as the not-found sentinel)."""
    impl = _unwrap(container)
    return _not_found_to_none(swig_function("find", impl)(impl, value))


def find_if(container, predicate) -> int | None:
    """std::find_if. `predicate(value) -> bool` is called from C++ once
    per element (in container order) until it returns true. Returns the
    matching index, or None if no element satisfies it."""
    impl = _unwrap(container)
    return _not_found_to_none(swig_function("find_if", impl)(impl, predicate))


def count(container, value) -> int:
    """std::count."""
    impl = _unwrap(container)
    return swig_function("count", impl)(impl, value)


def count_if(container, predicate) -> int:
    """std::count_if. `predicate(value) -> bool`."""
    impl = _unwrap(container)
    return swig_function("count_if", impl)(impl, predicate)


# ===========================================================================
# Min / max
# ===========================================================================


def min_element(container) -> int:
    """std::min_element, returned as an index. Raises IndexError on an
    empty container (there is no well-defined index to return)."""
    impl = _unwrap(container)
    return swig_function("min_element", impl)(impl)


def max_element(container) -> int:
    """std::max_element, returned as an index. Raises IndexError on an
    empty container."""
    impl = _unwrap(container)
    return swig_function("max_element", impl)(impl)


def minmax_element(container) -> tuple[int, int]:
    """std::minmax_element, returned as a (min_index, max_index) tuple.
    Raises IndexError on an empty container."""
    impl = _unwrap(container)
    return swig_function("minmax_element", impl)(impl)


# ===========================================================================
# Modification
# ===========================================================================


def replace(container, old_value, new_value) -> None:
    """std::replace: every element equal to `old_value` becomes `new_value`."""
    impl = _unwrap(container)
    swig_function("replace", impl)(impl, old_value, new_value)


def replace_if(container, predicate, new_value) -> None:
    """std::replace_if: every element for which `predicate(value)` is
    true becomes `new_value`."""
    impl = _unwrap(container)
    swig_function("replace_if", impl)(impl, predicate, new_value)


def remove(container, value) -> None:
    """Erase-remove idiom (std::remove + container.erase): every element
    equal to `value` is removed and the container shrinks accordingly --
    unlike bare std::remove, which only leaves logical garbage at the end
    without actually shrinking anything."""
    impl = _unwrap(container)
    swig_function("remove", impl)(impl, value)


def remove_if(container, predicate) -> None:
    """Erase-remove idiom with a predicate: every element for which
    `predicate(value)` is true is removed and the container shrinks."""
    impl = _unwrap(container)
    swig_function("remove_if", impl)(impl, predicate)


def unique(container) -> None:
    """Erase-remove idiom over std::unique: removes *consecutive*
    duplicate elements in place and shrinks the container. Run sort()
    first if you want all duplicates removed, not just adjacent ones --
    same precondition as plain std::unique."""
    impl = _unwrap(container)
    swig_function("unique", impl)(impl)


def unique_copy(container):
    """std::unique_copy: returns a *new* container with consecutive
    duplicates removed, leaving `container` untouched."""
    impl = _unwrap(container)
    return wrap_result(suffix_of(impl), swig_function("unique_copy", impl)(impl))


def fill(container, value) -> None:
    """std::fill: every element becomes `value`."""
    impl = _unwrap(container)
    swig_function("fill", impl)(impl, value)


def fill_n(container, n: int, value) -> None:
    """std::fill_n: the first `n` elements become `value`. Raises
    IndexError if n is negative or exceeds len(container)."""
    impl = _unwrap(container)
    swig_function("fill_n", impl)(impl, n, value)


def generate(container, generator) -> None:
    """std::generate: every element is replaced by `generator()`,
    called once per element from C++, in order."""
    impl = _unwrap(container)
    swig_function("generate", impl)(impl, generator)


def generate_n(container, n: int, generator) -> None:
    """std::generate_n: the first `n` elements are replaced by
    `generator()`. Raises IndexError if n is negative or exceeds
    len(container)."""
    impl = _unwrap(container)
    swig_function("generate_n", impl)(impl, n, generator)


def swap_ranges(a, b) -> None:
    """std::swap_ranges: swaps elements of `a` and `b` pairwise, up to
    the length of the shorter one (matching std::swap_ranges' own
    contract). Both must be the same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("swap_ranges", a_impl, b_impl)
    swig_function("swap_ranges", a_impl)(a_impl, b_impl)


# ===========================================================================
# Reordering
# ===========================================================================


def rotate(container, n: int) -> None:
    """std::rotate: the element at index `n` becomes the new first
    element, in place. Raises IndexError if n is out of range."""
    impl = _unwrap(container)
    swig_function("rotate", impl)(impl, n)


def rotate_copy(container, n: int):
    """std::rotate_copy: returns a new, rotated container; `container`
    is left untouched. Raises IndexError if n is out of range."""
    impl = _unwrap(container)
    return wrap_result(suffix_of(impl), swig_function("rotate_copy", impl)(impl, n))


def shuffle(container, seed: int | None = None) -> None:
    """std::shuffle using std::mt19937. `seed=None` (default) seeds from
    std::random_device (nondeterministic); pass an int for a
    reproducible shuffle, e.g. in tests."""
    impl = _unwrap(container)
    swig_function("shuffle", impl)(impl, -1 if seed is None else seed)


# ===========================================================================
# Partitioning
# ===========================================================================


def partition(container, predicate) -> int:
    """std::partition: reorders `container` in place so all elements for
    which `predicate(value)` is true come first. Returns the partition
    point (index of the first "false" element)."""
    impl = _unwrap(container)
    return swig_function("partition", impl)(impl, predicate)


def stable_partition(container, predicate) -> int:
    """Like partition(), but preserves the relative order within each
    group (at the cost of being slower)."""
    impl = _unwrap(container)
    return swig_function("stable_partition", impl)(impl, predicate)


def partition_copy(container, predicate):
    """std::partition_copy: returns a (matched, unmatched) tuple of new
    containers; `container` is left untouched."""
    impl = _unwrap(container)
    suffix = suffix_of(impl)
    matched, unmatched = swig_function("partition_copy", impl)(impl, predicate)
    return (wrap_result(suffix, matched), wrap_result(suffix, unmatched))


def is_partitioned(container, predicate) -> bool:
    """std::is_partitioned: true if every element satisfying `predicate`
    comes before every element that doesn't."""
    impl = _unwrap(container)
    return swig_function("is_partitioned", impl)(impl, predicate)


def partition_point(container, predicate) -> int:
    """std::partition_point: the index of the first element for which
    `predicate(value)` is false. `container` must already be partitioned
    by `predicate` (same precondition as the C++ algorithm)."""
    impl = _unwrap(container)
    return swig_function("partition_point", impl)(impl, predicate)


# ===========================================================================
# Merging (both ranges must already be sorted ascending)
# ===========================================================================


def merge(a, b):
    """std::merge: returns a new, sorted container containing all
    elements of `a` and `b`. Both must already be sorted ascending and
    the same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("merge", a_impl, b_impl)
    return wrap_result(suffix_of(a_impl), swig_function("merge", a_impl)(a_impl, b_impl))


def inplace_merge(container, mid: int) -> None:
    """std::inplace_merge: merges the two consecutive sorted subranges
    container[:mid] and container[mid:] in place. Both subranges must
    already be sorted ascending. Raises IndexError if mid is out of
    range."""
    impl = _unwrap(container)
    swig_function("inplace_merge", impl)(impl, mid)


# ===========================================================================
# Set algorithms (both ranges must already be sorted ascending)
# ===========================================================================


def set_union(a, b):
    """std::set_union. Both must already be sorted ascending and the
    same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("set_union", a_impl, b_impl)
    return wrap_result(suffix_of(a_impl), swig_function("set_union", a_impl)(a_impl, b_impl))


def set_intersection(a, b):
    """std::set_intersection. Both must already be sorted ascending and
    the same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("set_intersection", a_impl, b_impl)
    return wrap_result(suffix_of(a_impl), swig_function("set_intersection", a_impl)(a_impl, b_impl))


def set_difference(a, b):
    """std::set_difference. Both must already be sorted ascending and
    the same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("set_difference", a_impl, b_impl)
    return wrap_result(suffix_of(a_impl), swig_function("set_difference", a_impl)(a_impl, b_impl))


def set_symmetric_difference(a, b):
    """std::set_symmetric_difference. Both must already be sorted
    ascending and the same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("set_symmetric_difference", a_impl, b_impl)
    return wrap_result(suffix_of(a_impl), swig_function("set_symmetric_difference", a_impl)(a_impl, b_impl))


def includes(a, b) -> bool:
    """std::includes: true if every element of `b` is present in `a`.
    Both must already be sorted ascending and the same container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("includes", a_impl, b_impl)
    return swig_function("includes", a_impl)(a_impl, b_impl)


# ===========================================================================
# Heap
# ===========================================================================


def make_heap(container) -> None:
    """std::make_heap: rearranges `container` into a max-heap in place."""
    impl = _unwrap(container)
    swig_function("make_heap", impl)(impl)


def push_heap(container) -> None:
    """std::push_heap. Matches the STL contract exactly: the new element
    must already be at the back of `container` (e.g. via .append()/
    .push_back()) before calling this."""
    impl = _unwrap(container)
    swig_function("push_heap", impl)(impl)


def pop_heap(container) -> None:
    """std::pop_heap. Matches the STL contract exactly: moves the max to
    the back but does not remove it -- call container.pop() afterward to
    actually remove it."""
    impl = _unwrap(container)
    swig_function("pop_heap", impl)(impl)


def sort_heap(container) -> None:
    """std::sort_heap: turns a valid heap into a fully sorted range in
    place. `container` must already satisfy the heap property."""
    impl = _unwrap(container)
    swig_function("sort_heap", impl)(impl)


def is_heap(container) -> bool:
    """std::is_heap."""
    impl = _unwrap(container)
    return swig_function("is_heap", impl)(impl)


def is_heap_until(container) -> int:
    """std::is_heap_until: the index up to which the heap property
    holds."""
    impl = _unwrap(container)
    return swig_function("is_heap_until", impl)(impl)


# ===========================================================================
# Permutation
# ===========================================================================


def next_permutation(container) -> bool:
    """std::next_permutation: rearranges `container` in place into the
    next lexicographic permutation. Returns False (and leaves `container`
    sorted ascending) if it was already the last permutation."""
    impl = _unwrap(container)
    return swig_function("next_permutation", impl)(impl)


def prev_permutation(container) -> bool:
    """std::prev_permutation: the mirror image of next_permutation()."""
    impl = _unwrap(container)
    return swig_function("prev_permutation", impl)(impl)


def is_permutation(a, b) -> bool:
    """std::is_permutation: true if `a` and `b` contain the same
    elements, possibly in a different order. Both must be the same
    container/type."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("is_permutation", a_impl, b_impl)
    return swig_function("is_permutation", a_impl)(a_impl, b_impl)


# ===========================================================================
# Numeric (<numeric>)
# ===========================================================================


def accumulate(container, init):
    """std::accumulate. `init` is required rather than defaulted to 0 --
    there's no single sensible default across int/float/str (for str
    containers this performs concatenation via operator+, so `init`
    should be "")."""
    impl = _unwrap(container)
    return swig_function("accumulate", impl)(impl, init)


def adjacent_difference(container):
    """std::adjacent_difference: returns a new container the same length
    as `container`, where element 0 is unchanged and element i (i>0) is
    container[i] - container[i-1]. int/float containers only (needs
    operator-)."""
    impl = _unwrap(container)
    return wrap_result(suffix_of(impl), swig_function("adjacent_difference", impl)(impl))


def partial_sum(container):
    """std::partial_sum: returns a new container of running totals."""
    impl = _unwrap(container)
    return wrap_result(suffix_of(impl), swig_function("partial_sum", impl)(impl))


def inner_product(a, b, init):
    """std::inner_product (dot product): sum(a[i] * b[i]) + init. Both
    must be the same length, same container/type. int/float containers
    only (needs operator*)."""
    a_impl, b_impl = _unwrap(a), _unwrap(b)
    require_same_type("inner_product", a_impl, b_impl)
    if len(a_impl) != len(b_impl):
        raise ValueError(
            "algokit_ds.algorithms.inner_product requires both containers to be the same length"
        )
    return swig_function("inner_product", a_impl)(a_impl, b_impl, init)


def iota(container, start_value) -> None:
    """std::iota: fills `container` in place with start_value,
    start_value + 1, start_value + 2, .... int/float containers only
    (std::string has no operator++)."""
    impl = _unwrap(container)
    swig_function("iota", impl)(impl, start_value)
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
EOF

echo "Writing tests/test_algorithms_extended.py"
cat > tests/test_algorithms_extended.py << 'EOF'
import pytest

from algokit_ds import deque, stack, vector
from algokit_ds.algorithms import (
    accumulate,
    adjacent_difference,
    count,
    count_if,
    find,
    find_if,
    fill,
    fill_n,
    generate,
    generate_n,
    includes,
    inner_product,
    inplace_merge,
    iota,
    is_heap,
    is_heap_until,
    is_partitioned,
    is_permutation,
    make_heap,
    max_element,
    merge,
    min_element,
    minmax_element,
    next_permutation,
    partial_sum,
    partition,
    partition_copy,
    partition_point,
    pop_heap,
    prev_permutation,
    push_heap,
    remove,
    remove_if,
    replace,
    replace_if,
    rotate,
    rotate_copy,
    set_difference,
    set_intersection,
    set_symmetric_difference,
    set_union,
    shuffle,
    sort,
    sort_heap,
    stable_partition,
    swap_ranges,
    unique,
    unique_copy,
)


# ===========================================================================
# Searching
# ===========================================================================


def test_find_and_find_if():
    v = vector(int, [10, 20, 30, 40])
    assert find(v, 30) == 2
    assert find(v, 99) is None
    assert find_if(v, lambda x: x > 25) == 2
    assert find_if(v, lambda x: x > 1000) is None


def test_count_and_count_if():
    v = vector(int, [1, 2, 2, 3, 2])
    assert count(v, 2) == 3
    assert count_if(v, lambda x: x % 2 == 0) == 3


# ===========================================================================
# Min / max
# ===========================================================================


def test_min_max_element():
    v = vector(int, [5, 1, 9, 3])
    assert min_element(v) == 1
    assert max_element(v) == 2
    assert minmax_element(v) == (1, 2)


def test_min_element_empty_raises_index_error():
    with pytest.raises(IndexError):
        min_element(vector(int, []))
    with pytest.raises(IndexError):
        max_element(vector(int, []))
    with pytest.raises(IndexError):
        minmax_element(vector(int, []))


# ===========================================================================
# Modification
# ===========================================================================


def test_replace_and_replace_if():
    v = vector(int, [1, 2, 2, 3])
    replace(v, 2, 99)
    assert list(v) == [1, 99, 99, 3]

    v2 = vector(int, [1, 2, 3, 4])
    replace_if(v2, lambda x: x % 2 == 0, 0)
    assert list(v2) == [1, 0, 3, 0]


def test_remove_and_remove_if_actually_shrink():
    v = vector(int, [1, 2, 2, 3])
    remove(v, 2)
    assert list(v) == [1, 3]
    assert len(v) == 2

    v2 = vector(int, [1, 2, 3, 4, 5])
    remove_if(v2, lambda x: x % 2 == 0)
    assert list(v2) == [1, 3, 5]


def test_unique_and_unique_copy():
    v = vector(int, [1, 1, 2, 2, 3])
    unique(v)
    assert list(v) == [1, 2, 3]

    v2 = vector(int, [1, 1, 2, 2, 3])
    result = unique_copy(v2)
    assert list(result) == [1, 2, 3]
    assert list(v2) == [1, 1, 2, 2, 3]  # untouched
    assert type(result).__name__ == "Vector"


def test_fill_and_fill_n():
    v = vector(int, [0, 0, 0])
    fill(v, 7)
    assert list(v) == [7, 7, 7]

    v2 = vector(int, [0, 0, 0])
    fill_n(v2, 2, 1)
    assert list(v2) == [1, 1, 0]


def test_fill_n_out_of_range_raises_index_error():
    with pytest.raises(IndexError):
        fill_n(vector(int, [1, 2]), 5, 0)


def test_generate_and_generate_n():
    values = iter([1, 2, 3])
    v = vector(int, [0, 0, 0])
    generate(v, lambda: next(values))
    assert list(v) == [1, 2, 3]

    values2 = iter([9, 9])
    v2 = vector(int, [0, 0, 0])
    generate_n(v2, 2, lambda: next(values2))
    assert list(v2) == [9, 9, 0]


def test_swap_ranges_overlapping_prefix_only():
    a = vector(int, [1, 2, 3])
    b = vector(int, [9, 9, 9, 9])
    swap_ranges(a, b)
    assert list(a) == [9, 9, 9]
    assert list(b) == [1, 2, 3, 9]


# ===========================================================================
# Reordering
# ===========================================================================


def test_rotate_and_rotate_copy():
    v = vector(int, [1, 2, 3, 4, 5])
    rotate(v, 2)
    assert list(v) == [3, 4, 5, 1, 2]

    v2 = vector(int, [1, 2, 3, 4, 5])
    result = rotate_copy(v2, 2)
    assert list(result) == [3, 4, 5, 1, 2]
    assert list(v2) == [1, 2, 3, 4, 5]


def test_rotate_out_of_range_raises_index_error():
    with pytest.raises(IndexError):
        rotate(vector(int, [1, 2, 3]), 10)


def test_shuffle_is_deterministic_with_a_seed():
    v1 = vector(int, list(range(30)))
    shuffle(v1, seed=42)
    v2 = vector(int, list(range(30)))
    shuffle(v2, seed=42)
    assert list(v1) == list(v2)
    assert list(v1) != list(range(30))
    assert sorted(v1) == list(range(30))


# ===========================================================================
# Partitioning
# ===========================================================================


def test_partition():
    v = vector(int, [1, 2, 3, 4, 5, 6])
    point = partition(v, lambda x: x % 2 == 0)
    assert point == 3
    assert sorted(list(v)[:point]) == [2, 4, 6]
    assert sorted(list(v)[point:]) == [1, 3, 5]


def test_stable_partition_preserves_relative_order():
    v = vector(int, [1, 2, 3, 4, 5, 6])
    point = stable_partition(v, lambda x: x % 2 == 0)
    assert list(v)[:point] == [2, 4, 6]
    assert list(v)[point:] == [1, 3, 5]


def test_partition_copy():
    v = vector(int, [1, 2, 3, 4, 5, 6])
    matched, unmatched = partition_copy(v, lambda x: x % 2 == 0)
    assert list(matched) == [2, 4, 6]
    assert list(unmatched) == [1, 3, 5]
    assert list(v) == [1, 2, 3, 4, 5, 6]  # untouched


def test_is_partitioned_and_partition_point():
    assert is_partitioned(vector(int, [2, 4, 1, 3]), lambda x: x % 2 == 0)
    assert not is_partitioned(vector(int, [2, 1, 4, 3]), lambda x: x % 2 == 0)
    assert partition_point(vector(int, [2, 4, 6, 1, 3]), lambda x: x % 2 == 0) == 3


# ===========================================================================
# Merging
# ===========================================================================


def test_merge():
    result = merge(vector(int, [1, 3, 5]), vector(int, [2, 4, 6]))
    assert list(result) == [1, 2, 3, 4, 5, 6]
    assert type(result).__name__ == "Vector"


def test_merge_requires_same_type():
    with pytest.raises(TypeError):
        merge(vector(int, [1, 2]), vector(str, ["a"]))


def test_inplace_merge():
    v = vector(int, [1, 3, 5, 2, 4, 6])
    inplace_merge(v, 3)
    assert list(v) == [1, 2, 3, 4, 5, 6]


# ===========================================================================
# Set algorithms
# ===========================================================================


def test_set_algorithms():
    a, b = vector(int, [1, 2, 3, 4]), vector(int, [3, 4, 5, 6])
    assert list(set_union(a, b)) == [1, 2, 3, 4, 5, 6]
    assert list(set_intersection(a, b)) == [3, 4]
    assert list(set_difference(a, b)) == [1, 2]
    assert list(set_symmetric_difference(a, b)) == [1, 2, 5, 6]


def test_includes():
    assert includes(vector(int, [1, 2, 3, 4, 5]), vector(int, [2, 4]))
    assert not includes(vector(int, [1, 2, 3]), vector(int, [4]))


# ===========================================================================
# Heap
# ===========================================================================


def test_heap_roundtrip():
    h = vector(int, [3, 1, 4, 1, 5, 9, 2, 6])
    make_heap(h)
    assert is_heap(h)

    h.append(100)
    push_heap(h)
    assert is_heap(h)
    assert h[0] == 100

    pop_heap(h)
    top = h.pop()
    assert top == 100
    assert is_heap(h)

    sort_heap(h)
    assert list(h) == sorted([3, 1, 4, 1, 5, 9, 2, 6])


def test_is_heap_until():
    assert is_heap_until(vector(int, [9, 5, 4, 1, 1, 3])) == 6
    assert is_heap_until(vector(int, [1, 2, 3])) == 1


# ===========================================================================
# Permutation
# ===========================================================================


def test_next_and_prev_permutation():
    v = vector(int, [1, 2, 3])
    assert next_permutation(v) is True
    assert list(v) == [1, 3, 2]

    v2 = vector(int, [3, 2, 1])
    assert next_permutation(v2) is False
    assert list(v2) == [1, 2, 3]  # wraps to the first permutation

    v3 = vector(int, [1, 2, 3])
    assert prev_permutation(v3) is False
    assert list(v3) == [3, 2, 1]  # wraps to the last permutation


def test_is_permutation():
    assert is_permutation(vector(int, [1, 2, 3]), vector(int, [3, 1, 2]))
    assert not is_permutation(vector(int, [1, 2, 3]), vector(int, [1, 2, 4]))


# ===========================================================================
# Numeric
# ===========================================================================


def test_accumulate():
    assert accumulate(vector(int, [1, 2, 3, 4]), 0) == 10
    assert accumulate(vector(str, ["a", "b", "c"]), "") == "abc"


def test_adjacent_difference_and_partial_sum():
    v = vector(int, [1, 2, 4, 7])
    assert list(adjacent_difference(v)) == [1, 1, 2, 3]
    assert list(partial_sum(v)) == [1, 3, 7, 14]


def test_inner_product():
    a, b = vector(int, [1, 2, 3]), vector(int, [4, 5, 6])
    assert inner_product(a, b, 0) == 32


def test_iota():
    v = vector(int, [0, 0, 0, 0])
    iota(v, 5)
    assert list(v) == [5, 6, 7, 8]


# ===========================================================================
# Cross-cutting: deque coverage, exception handling, container restrictions
# ===========================================================================


def test_works_on_deque_too():
    d = deque(int, [5, 3, 1, 4])
    sort(d)
    assert list(d) == [1, 3, 4, 5]

    result = merge(deque(int, [1, 3]), deque(int, [2, 4]))
    assert list(result) == [1, 2, 3, 4]
    assert type(result).__name__ == "Deque"


def test_predicate_exception_propagates_unchanged():
    class MyError(ValueError):
        pass

    def bad_predicate(x):
        raise MyError("boom")

    with pytest.raises(MyError, match="boom"):
        find_if(vector(int, [1, 2, 3]), bad_predicate)


def test_unsupported_container_raises_type_error():
    s = stack(int)
    s.push(1)
    with pytest.raises(TypeError):
        sort(s)
    with pytest.raises(TypeError):
        find(s, 1)
EOF

echo "Writing benchmarks/algorithms_benchmark.py"
cat > benchmarks/algorithms_benchmark.py << 'EOF'
#!/usr/bin/env python3
"""Benchmarks algokit_ds.algorithms against the equivalent pure-Python
operation, to make the "operates directly on the C++ container, no copy"
claim concrete rather than just asserted.

Usage:
    python3 benchmarks/algorithms_benchmark.py
    python3 benchmarks/algorithms_benchmark.py --size 2000000
"""

from __future__ import annotations

import argparse
import random
import time

from algokit_ds import vector
from algokit_ds.algorithms import (
    accumulate,
    binary_search,
    find,
    lower_bound,
    sort,
)


def timed(fn, *args, **kwargs):
    start = time.perf_counter()
    result = fn(*args, **kwargs)
    elapsed = time.perf_counter() - start
    return result, elapsed


def bench_sort(size: int) -> None:
    data = [random.randint(0, size) for _ in range(size)]

    py_list = list(data)
    _, py_time = timed(py_list.sort)

    v = vector(int, data)
    _, cpp_time = timed(sort, v)

    assert list(v) == py_list
    print(f"sort            n={size:>9}  python: {py_time:8.4f}s   algokit_ds: {cpp_time:8.4f}s   ratio: {py_time / cpp_time:5.2f}x")


def bench_find(size: int) -> None:
    data = [random.randint(0, size) for _ in range(size)]
    needle = data[-1]

    py_list = list(data)
    _, py_time = timed(lambda: py_list.index(needle) if needle in py_list else -1)

    v = vector(int, data)
    _, cpp_time = timed(find, v, needle)

    print(f"find            n={size:>9}  python: {py_time:8.4f}s   algokit_ds: {cpp_time:8.4f}s   ratio: {py_time / cpp_time:5.2f}x")


def bench_accumulate(size: int) -> None:
    data = [random.random() for _ in range(size)]

    py_list = list(data)
    _, py_time = timed(sum, py_list)

    v = vector(float, data)
    _, cpp_time = timed(accumulate, v, 0.0)

    print(f"accumulate      n={size:>9}  python: {py_time:8.4f}s   algokit_ds: {cpp_time:8.4f}s   ratio: {py_time / cpp_time:5.2f}x")


def bench_binary_search(size: int) -> None:
    data = sorted(random.randint(0, size) for _ in range(size))
    needle = data[size // 2]

    py_list = list(data)

    def py_bisect():
        import bisect

        return bisect.bisect_left(py_list, needle)

    _, py_time = timed(py_bisect)

    v = vector(int, data)
    _, cpp_time = timed(lambda: (binary_search(v, needle), lower_bound(v, needle)))

    print(f"binary_search   n={size:>9}  python: {py_time:8.4f}s   algokit_ds: {cpp_time:8.4f}s   ratio: {py_time / cpp_time:5.2f}x")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size", type=int, default=500_000, help="element count per benchmark")
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    random.seed(args.seed)

    print(f"algokit_ds.algorithms micro-benchmarks (n={args.size})\n")
    bench_sort(args.size)
    bench_find(args.size)
    bench_accumulate(args.size)
    bench_binary_search(args.size)
    print("\nNote: 'find'/'binary_search' compare against Python's closest")
    print("stdlib equivalent (list.index/in, bisect), not a naive linear")
    print("scan reimplementation, so these ratios are conservative.")


if __name__ == "__main__":
    main()
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
    algorithms
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
    <algorithm>
    <numeric>
    <random>
    <utility>
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

echo ""
echo "Done. New/updated files:"
echo "  cpp/algorithms/algorithms.hpp        (extended: ~50 new algorithm wrappers)"
echo "  cpp/algorithms/algorithms.cpp        (unchanged explicit instantiations)"
echo "  cpp/algorithms/py_callback.hpp       (predicate/generator callback bridge, exception-safe)"
echo "  swig/algorithms.i                    (regenerated, 499 lines)"
echo "  tools/algorithms_spec.py             (new: declarative spec table)"
echo "  tools/generate_algorithms_swig.py    (new: spec -> swig/algorithms.i generator)"
echo "  python/algokit_ds/algorithms/__init__.py"
echo "  python/algokit_ds/algorithms/_algorithms.py"
echo "  python/algokit_ds/algorithms/_registry.py"
echo "  tests/test_algorithms_extended.py    (new: 34 tests covering every algorithm group)"
echo "  benchmarks/algorithms_benchmark.py   (new)"
echo "  CMakeLists.txt (overwritten: algorithms module moved first in build order)"
echo ""
echo "Next: rebuild and test with:"
echo "  rm -rf build dist *.egg-info python/algokit_ds.egg-info python/algokit_ds/_swig/*PYTHON_wrap.cxx python/algokit_ds/_swig/*.so python/algokit_ds/_swig/*.py"
echo "  pip uninstall -y algokit-ds"
echo "  time pip install ."
echo "  pytest tests/ -v"
echo "  python3 benchmarks/algorithms_benchmark.py"
