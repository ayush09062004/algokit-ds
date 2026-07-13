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
