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
