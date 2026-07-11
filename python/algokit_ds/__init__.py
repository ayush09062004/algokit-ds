"""AlgoKit DS -- Pythonic wrappers around C++ STL containers, backed by
native SWIG bindings.

    from algokit_ds import vector, map

    v = vector(int, [1, 2, 3])
    m = map(str, int)
    m["a"] = 1

Unsupported for v1 (see README): unordered_multimap, priority_queue.
"""

from .vector import vector
from .deque import deque
from .stack import stack
from .queue import queue
from .set import set
from .multiset import multiset
from .unordered_set import unordered_set
from .unordered_multiset import unordered_multiset
from .map import map
from .multimap import multimap
from .unordered_map import unordered_map

__version__ = "0.1.0"

__all__ = [
    "vector",
    "deque",
    "stack",
    "queue",
    "set",
    "multiset",
    "unordered_set",
    "unordered_multiset",
    "map",
    "multimap",
    "unordered_map",
]
