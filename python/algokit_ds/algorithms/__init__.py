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
