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
