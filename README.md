# AlgoKit DS
**Native C++ STL Containers & Algorithms for Python**

Pythonic wrappers around native C++ STL containers and algorithms backed by native [SWIG](https://www.swig.org/) bindings. AlgoKit DS provides familiar C++ STL containers such as `std::vector`,`std::deque`, `std::map`, and `std::unordered_set`, together with 46 native STL algorithms — sorting, searching, partitioning, heaps, merging, set operations, permutations, and `<numeric>` — all through a clean and Pythonic interface.

Unlike most Python data structure libraries, AlgoKit DS executes operations directly on the underlying C++ containers without converting them into Python
lists. You get real `std::vector`,`std::map`, `std::unordered_set`, etc. performance under a small, consistent Python API.

Inspired by [cstl](https://github.com/fuzihaofzh/cstl) — see
[Credits](#credits) below.

## Quick Installation Instructions(≈1.5–2 minutes)
> **Note:** The first installation compiles the native C++ extension, so it may take around **1.5–2 minutes** for complete installation.

```bash
!apt-get update -qq
!apt-get install -y swig

!pip install git+https://github.com/ayush09062004/algokit-ds.git
```

```python
from algokit_ds import vector, map

v = vector(int, [1, 2, 3])
v.append(4)
print(v)  # Vector([1, 2, 3, 4])

m = map(str, int)
m["a"] = 1
print(m["a"])  # 1
```
```python
from algokit_ds import vector
from algokit_ds.algorithms import (
    sort,
    binary_search,
)

v = vector(int, [5,4,2,1,3])

sort(v)

print(v)
# Vector([1,2,3,4,5])

print(binary_search(v,3))
# True
```

## Table of contents

- [Install](#install)
- [Supported containers](#supported-containers)
- [Supported element types](#supported-element-types)
- [API reference](#api-reference)
  - [vector](#vector)
  - [deque](#deque)
  - [stack](#stack)
  - [queue](#queue)
  - [set / multiset / unordered\_set / unordered\_multiset](#set--multiset--unordered_set--unordered_multiset)
  - [map / multimap / unordered\_map](#map--multimap--unordered_map)
- [Known limitations](#known-limitations)
- [Supported algorithms](#supported-algorithms)
- [Documentation site](#documentation-site)
- [Architecture](#architecture)
- [Extending](#extending)
- [Development](#development)
- [Credits](#credits)
- [License](#license)

## Install from Source

Building from source requires a C++17 compiler, CMake >= 3.16, and
SWIG >= 4.0 (the extensions are compiled during `pip install`):

```bash
git clone https://github.com/ayush09062004/algokit-ds
cd algokit-ds
pip install .
```

On a machine that doesn't already have the toolchain (a fresh Codespace,
Colab runtime, or CI container), install it first:

```bash
apt-get update -qq
apt-get install -y -qq --no-install-recommends cmake swig ninja-build ccache
```

`ninja` and `ccache` are optional but recommended — the build auto-detects
and uses both when present. `ninja` schedules the 11 independent native
modules more efficiently than the default Makefiles generator, and `ccache`
makes every reinstall in the same session dramatically faster (a rebuild
after touching one file drops from ~1 minute to a few seconds once the
cache is warm), which matters most in ephemeral/notebook environments like
Google Colab where you may reinstall several times per session.

## Supported containers

| Python API                         | C++ type                     |
|-------------------------------------|-------------------------------|
| `vector(T)`                         | `std::vector<T>`             |
| `deque(T)`                          | `std::deque<T>`               |
| `stack(T)`                          | `std::stack<T>`               |
| `queue(T)`                          | `std::queue<T>`               |
| `set(T)`                            | `std::set<T>`                 |
| `multiset(T)`                       | `std::multiset<T>`            |
| `unordered_set(T)`                  | `std::unordered_set<T>`       |
| `unordered_multiset(T)`             | `std::unordered_multiset<T>`  |
| `map(K, V)`                         | `std::map<K, V>`              |
| `multimap(K, V)`                    | `std::multimap<K, V>`         |
| `unordered_map(K, V)`               | `std::unordered_map<K, V>`    |

**Not yet supported**: `unordered_multimap` (SWIG lacks traits for
`std::pair` needed to wrap it) and `priority_queue` (not exposed by SWIG's
standard library headers).

## Supported element types

`T` / `K` / `V` currently accept `int`, `float`, `str`, in the
combinations registered per container below. Passing an unregistered type
(or type combination, for maps) raises a `TypeError` listing the types
that are actually supported — it won't silently coerce or fail with a
confusing SWIG error.

```python
>>> from algokit_ds import vector
>>> vector(bool)
TypeError: vector<bool> is not supported. Supported types: float, int, str
```

## API reference

Every constructor takes the C++ element type(s) first, followed by
optional STL-style constructor arguments.

### vector

```python
from algokit_ds import vector

v = vector(int)             # empty
v = vector(int, 10)         # 10 zero-initialized elements
v = vector(int, 10, 0)      # 10 elements, each = 0
v = vector(int, [1, 2, 3])  # from a list
```

Types: `int`, `float`, `str`.

| Method / operator | Behavior |
|---|---|
| `.append(x)` | Pythonic alias for `push_back`. |
| `.push_back(x)` | STL name, identical to `.append(x)`. |
| `.pop()` | Removes & returns the last element (Pythonic). |
| `.pop_back()` | STL name: removes the last element, returns nothing. |
| `len(v)` | Number of elements. |
| `v[i]` / `v[i] = x` | Indexed get/set. Negative indices work. |
| `for x in v: ...` | Iteration. |
| `x in v` | Membership test. |
| `v == other` | Element-wise equality — see [Known limitations](#known-limitations). |
| `repr(v)` | `Vector([...])`. |

### deque

```python
from algokit_ds import deque

d = deque(int)
d = deque(int, [1, 2, 3])
```

Types: `int`, `float`, `str`.

Adds, on top of the same API as `vector`:

| Method | Behavior |
|---|---|
| `.appendleft(x)` | Alias for `push_front`. |
| `.popleft()` | Removes & returns the first element. |
| `.push_front(x)` / `.pop_front()` | STL names. |

### stack

```python
from algokit_ds import stack

s = stack(int)
s.push(1)
s.top()
s.pop()
len(s)
```

Types: `int`, `float`, `str`.

`std::stack` supports neither iteration nor indexing in real C++, and this
wrapper preserves that honestly instead of faking a list-like interface.

| Method | Behavior |
|---|---|
| `.push(x)` | Push onto the top. |
| `.pop()` | Removes **and returns** the top value (unlike raw `std::stack::pop()`, which is `void`). |
| `.top()` | Peek at the top value without removing it. |
| `len(s)` | Number of elements. |
| `repr(s)` | `Stack(size=N)` — contents aren't shown since the container isn't iterable. |

### queue

```python
from algokit_ds import queue

q = queue(int)
q.push(1)
q.front()
q.back()
q.pop()
len(q)
```

Types: `int`, `float`, `str`.

`std::queue` supports neither iteration nor indexing in real C++, same as
`stack` above.

| Method | Behavior |
|---|---|
| `.push(x)` | Push onto the back. |
| `.pop()` | Removes **and returns** the front value (unlike raw `std::queue::pop()`, which is `void`). |
| `.front()` / `.back()` | Peek at either end without removing. |
| `len(q)` | Number of elements. |
| `repr(q)` | `Queue(size=N)`. |

### set / multiset / unordered\_set / unordered\_multiset

```python
from algokit_ds import set, multiset, unordered_set, unordered_multiset

s = set(int)
s.add(1)
1 in s
len(s)

ms = multiset(int)
ms.add(1); ms.add(1)
len(ms)  # 2 -- duplicates allowed
```

Types (all four containers): `int`, `float`, `str`.

All four expose `.add(x)` as one consistent method name, even though the
underlying SWIG bindings generate different names (`insert` / `add` /
`append`) per container.

| Method / operator | Behavior |
|---|---|
| `.add(x)` | Insert an element. |
| `len(s)` | Number of elements. |
| `for x in s: ...` | Iteration. |
| `x in s` | Membership test. |
| `s == other` | Element-wise equality — see [Known limitations](#known-limitations). |
| `repr(s)` | `Set([...])` / `Multiset([...])` / etc. |

`set` and `map` are exported under those names, which shadow the Python
builtins of the same name *within your own module* once you
`from algokit_ds import set, map`. This is intentional (it mirrors the
C++ names), but keep it in mind if you also need the builtins in the same
file — import them under an alias, e.g. `from algokit_ds import set as cset`.

### map / multimap / unordered\_map

```python
from algokit_ds import map, multimap, unordered_map

m = map(str, int)
m["a"] = 1
m.keys()
m.values()
m.items()
```

Key/value type combinations currently registered:

| Container | `(K, V)` combinations |
|---|---|
| `map`, `multimap`, `unordered_map` | `(int, int)`, `(int, float)`, `(str, int)`, `(str, str)` |

Behave like a Python `dict` for the operations below:

| Method / operator | Behavior |
|---|---|
| `m[k] = v` | Insert or update. |
| `m[k]` | Lookup — see [Known limitations](#known-limitations) re: the exception raised on a missing key. |
| `k in m` | Membership test on keys. |
| `len(m)` | Number of entries. |
| `.keys()` / `.values()` / `.items()` | Same shape as the SWIG proxy's dict-style accessors. |
| `for k in m: ...` | Iterates keys. |
| `m == other` | Element-wise equality — see [Known limitations](#known-limitations). |

`del m[k]` and `m.pop(k)` are **not currently implemented** — see below.

## Known limitations

These are honest, currently-open gaps rather than intended behavior.
Contributions welcome.

- **`del m[k]` / `m.pop(k)` are not implemented** on `map` / `multimap` /
  `unordered_map`. Both raise `AttributeError`. If you need removal today,
  rebuild the container without the key you want gone.
- **Missing-key lookup raises `IndexError`, not `KeyError`.** `m["missing"]`
  does not follow the usual Python dict contract, so `except KeyError:`
  won't catch it — catch `IndexError` instead until this is fixed.
- **Equality compares across container types.** `SizedWrapper.__eq__`
  currently checks "is this also some `SizedWrapper` with equal contents,"
  not "is this the *same kind* of container." So
  `vector(int, [1,2,3]) == set(int, [1,2,3])` currently returns `True`,
  which is misleading given the containers have different ordering/
  uniqueness semantics.
- **Slicing a `vector`/`deque` returns the raw SWIG proxy object**, not a
  wrapped `Vector`/`Deque` and not a Python `list`. `v[0:2]` leaks the
  underlying `algokit_ds._swig.*` type instead of staying inside the
  public API surface. Convert explicitly if needed:
  `list(v)[0:2]` or `vector(int, list(v[0:2]))`.
- Containers are intentionally unhashable (`__eq__` is defined without
  `__hash__`), consistent with how Python's own mutable containers behave
  — you can't put a `vector`/`set`/`map` wrapper directly into a `set` or
  use it as a `dict` key.

## Supported algorithms

Algorithms operate directly on the underlying native C++ STL containers —
nothing is copied into a Python list first, and nothing is reimplemented
in Python. 46 algorithms are currently exposed, spanning sorting,
searching, modification, reordering, partitioning, merging, set
operations, heaps, permutations, and `<numeric>`.

```python
from algokit_ds import vector
from algokit_ds.algorithms import (
    sort,
    stable_sort,
    reverse,
    binary_search,
    lower_bound,
    upper_bound,
)

v = vector(int,[5,4,2,1,3])

sort(v)

assert list(v)==[1,2,3,4,5]

reverse(v)

assert list(v)==[5,4,3,2,1]
```

Supported containers: `vector`, `deque`. Supported element types: `int`,
`float`, `str`, except where a function needs `operator-`, `operator*`,
or `operator++` (`adjacent_difference`, `inner_product`, `iota` — `int`
and `float` only, noted below). Functions taking a `predicate` or
`generator` accept a plain Python callable, invoked once per element
directly from C++; if it raises, the original exception propagates
unchanged. Functions marked **"sorted input"** carry the same
precondition as the underlying STL algorithm — they don't sort for you
and don't check.

### Sorting

| Function | STL equivalent | Description |
|---|---|---|
| `sort(container)` | `std::sort` | Sorts in ascending order, in place. |
| `stable_sort(container)` | `std::stable_sort` | Like `sort`, but preserves the relative order of equal elements. |

### Searching

| Function | STL equivalent | Description |
|---|---|---|
| `binary_search(container, x)` | `std::binary_search` | *(sorted input)* Returns `True` if `x` is present. |
| `lower_bound(container, x)` | `std::lower_bound` | *(sorted input)* Index of the first element not less than `x`. |
| `upper_bound(container, x)` | `std::upper_bound` | *(sorted input)* Index of the first element greater than `x`. |
| `find(container, x)` | `std::find` | Index of the first match, or `None` if absent. |
| `find_if(container, predicate)` | `std::find_if` | Index of the first element satisfying `predicate(value)`, or `None`. |
| `count(container, x)` | `std::count` | Number of elements equal to `x`. |
| `count_if(container, predicate)` | `std::count_if` | Number of elements satisfying `predicate(value)`. |

### Min / max

| Function | STL equivalent | Description |
|---|---|---|
| `min_element(container)` | `std::min_element` | Index of the smallest element. Raises `IndexError` if empty. |
| `max_element(container)` | `std::max_element` | Index of the largest element. Raises `IndexError` if empty. |
| `minmax_element(container)` | `std::minmax_element` | `(min_index, max_index)` tuple. Raises `IndexError` if empty. |

### Modification

| Function | STL equivalent | Description |
|---|---|---|
| `replace(container, old, new)` | `std::replace` | Every element equal to `old` becomes `new`. |
| `replace_if(container, predicate, new)` | `std::replace_if` | Every element satisfying `predicate` becomes `new`. |
| `remove(container, x)` | erase-remove + `std::remove` | Removes every element equal to `x`; the container actually shrinks. |
| `remove_if(container, predicate)` | erase-remove + `std::remove_if` | Removes every element satisfying `predicate`; the container shrinks. |
| `unique(container)` | erase-remove + `std::unique` | Removes *consecutive* duplicates in place; `sort()` first for global dedup. |
| `unique_copy(container)` | `std::unique_copy` | Returns a **new** container with consecutive duplicates removed; leaves the original untouched. |
| `fill(container, x)` | `std::fill` | Every element becomes `x`. |
| `fill_n(container, n, x)` | `std::fill_n` | The first `n` elements become `x`. Raises `IndexError` if `n` is out of range. |
| `generate(container, generator)` | `std::generate` | Every element is replaced by `generator()`, called once per element from C++. |
| `generate_n(container, n, generator)` | `std::generate_n` | The first `n` elements are replaced by `generator()`. |
| `swap_ranges(a, b)` | `std::swap_ranges` | Swaps elements of `a`/`b` pairwise, up to the shorter length. Same container/type required. |

### Reordering

| Function | STL equivalent | Description |
|---|---|---|
| `rotate(container, n)` | `std::rotate` | The element at index `n` becomes the new first element, in place. |
| `rotate_copy(container, n)` | `std::rotate_copy` | Returns a **new**, rotated container; leaves the original untouched. |
| `shuffle(container, seed=None)` | `std::shuffle` (`std::mt19937`) | Random shuffle. `seed=None` uses `std::random_device`; pass an `int` for reproducibility. |

### Partitioning

| Function | STL equivalent | Description |
|---|---|---|
| `partition(container, predicate)` | `std::partition` | Reorders so matching elements come first; returns the partition index. |
| `stable_partition(container, predicate)` | `std::stable_partition` | Like `partition`, but preserves relative order within each group. |
| `partition_copy(container, predicate)` | `std::partition_copy` | Returns `(matched, unmatched)` new containers; leaves the original untouched. |
| `is_partitioned(container, predicate)` | `std::is_partitioned` | `True` if every matching element precedes every non-matching one. |
| `partition_point(container, predicate)` | `std::partition_point` | *(sorted input)* Index of the first element for which `predicate` is `False`. |

### Merging *(sorted input)*

| Function | STL equivalent | Description |
|---|---|---|
| `merge(a, b)` | `std::merge` | Returns a new, sorted container with all elements of `a` and `b`. |
| `inplace_merge(container, mid)` | `std::inplace_merge` | Merges the two sorted subranges `container[:mid]` and `container[mid:]` in place. |

### Set algorithms *(sorted input)*

| Function | STL equivalent | Description |
|---|---|---|
| `set_union(a, b)` | `std::set_union` | Elements present in `a`, `b`, or both. |
| `set_intersection(a, b)` | `std::set_intersection` | Elements present in both `a` and `b`. |
| `set_difference(a, b)` | `std::set_difference` | Elements present in `a` but not `b`. |
| `set_symmetric_difference(a, b)` | `std::set_symmetric_difference` | Elements present in exactly one of `a`, `b`. |
| `includes(a, b)` | `std::includes` | `True` if every element of `b` is present in `a`. |

### Heap

| Function | STL equivalent | Description |
|---|---|---|
| `make_heap(container)` | `std::make_heap` | Rearranges into a max-heap in place. |
| `push_heap(container)` | `std::push_heap` | The new element must already be at the back (e.g. via `.append()`) before calling. |
| `pop_heap(container)` | `std::pop_heap` | Moves the max to the back but doesn't remove it — call `.pop()` afterward. |
| `sort_heap(container)` | `std::sort_heap` | Turns a valid heap into a fully sorted range in place. |
| `is_heap(container)` | `std::is_heap` | `True` if the container satisfies the heap property. |
| `is_heap_until(container)` | `std::is_heap_until` | Index up to which the heap property holds. |

### Permutation

| Function | STL equivalent | Description |
|---|---|---|
| `next_permutation(container)` | `std::next_permutation` | In-place next lexicographic permutation. Returns `False` (and resets to ascending) after the last one. |
| `prev_permutation(container)` | `std::prev_permutation` | Mirror image of `next_permutation`. |
| `is_permutation(a, b)` | `std::is_permutation` | `True` if `a` and `b` hold the same elements in any order. |

### Numeric (`<numeric>`)

| Function | STL equivalent | Description |
|---|---|---|
| `accumulate(container, init)` | `std::accumulate` | Folds the container into a single value, starting from `init` (required — use `""` for `str`). |
| `adjacent_difference(container)` | `std::adjacent_difference` | New container where element `i>0` is `container[i] - container[i-1]`. `int`/`float` only. |
| `partial_sum(container)` | `std::partial_sum` | New container of running totals. |
| `inner_product(a, b, init)` | `std::inner_product` | Dot product: `sum(a[i] * b[i]) + init`. Same length required. `int`/`float` only. |
| `iota(container, start)` | `std::iota` | Fills in place with `start, start+1, start+2, ...`. `int`/`float` only. |

## Documentation site

A full interactive reference — every container and every algorithm with
a live, runnable visualization — ships in `docs/index.html`. Open it
directly in a browser, no build step required.


## Architecture

```
algokit-ds/
├── cpp/
│   ├── containers/
│   └── algorithms/
├── swig/
├── python/
│   └── algokit_ds/
│       ├── algorithms/
│       ├── vector.py
│       ├── deque.py
│       └── ...
├── tests/
└── CMakeLists.txt

```

Generated code and handwritten code are never in the same directory, so
there's no filename collision between e.g. the handwritten
`algokit_ds.vector` and the generated `algokit_ds._swig.vector`.

## Extending

### Adding a new wrapped type

1. Add a `%template(...)` instantiation to the matching `swig/<container>.i`
   file, e.g. in `swig/vector.i`:
   ```
   %template(BoolVector) std::vector<bool>;
   ```
2. Register it in the container's type-dispatch table, e.g. in
   `python/algokit_ds/vector.py`:
   ```python
   _TYPES = {
       int: _swig.IntVector,
       float: _swig.DoubleVector,
       str: _swig.StrVector,
       bool: _swig.BoolVector,   # new
   }
   ```

Nothing else changes — no wrapper logic to rewrite.

### Adding a new container

1. Write `swig/<name>.i` with the relevant `%include "std_*.i"` and
   `%template(...)` instantiations.
2. Add the module name to `ALGOKIT_MODULES` in `CMakeLists.txt`.
3. Write `python/algokit_ds/<name>.py`: a `_TYPES` dict plus a factory
   function returning one of the shared wrapper base classes from
   `_base.py` (`Wrapper`, `SizedWrapper`, `SetWrapper`, `MapWrapper`).
4. Export it from `python/algokit_ds/__init__.py`.
5. If you add a new common STL header, also add it to the
   `target_precompile_headers(algokit_pch PRIVATE ...)` list in
   `CMakeLists.txt` so every module benefits from it.

## Development

```bash
# Build the C++/SWIG layer in-place
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -GNinja
cmake --build build -j

# Run tests
pip install pytest
PYTHONPATH=python pytest tests/ -v
```

For fast iteration, install `ccache` — the build auto-detects and uses it
via `CMAKE_CXX_COMPILER_LAUNCHER`, so repeated builds after small edits are
dramatically faster than the first cold build.

## Credits

Inspired by [cstl](https://github.com/fuzihaofzh/cstl) by
[@fuzihaofzh](https://github.com/fuzihaofzh) — a SWIG-based C++ STL
wrapper for Python that first explored this idea (`std::vector`,
`std::unordered_map`, `std::unordered_set` as drop-in replacements for
Python's `list`/`dict`/`set`, aimed at sidestepping Python's
copy-on-write behavior in multiprocessing). AlgoKit DS takes a different
angle — a small consistent wrapper API across a much wider set of STL
containers (deque, stack, queue, ordered/unordered sets and maps,
multiset/multimap variants) with hand-written SWIG interfaces per
container — but the core idea of exposing real STL containers to Python
through SWIG bindings owes its inspiration to that project.

### Adding a new algorithm

1. Add a native C++ wrapper.
2. Export it through the SWIG interface.
3. Register the Python wrapper.
4. Export it from `algokit_ds.algorithms`.

No existing container code needs to change.

## License

MIT
