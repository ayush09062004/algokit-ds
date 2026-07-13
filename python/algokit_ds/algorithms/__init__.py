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
