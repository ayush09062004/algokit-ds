# AlgoKit DS
**Native C++ STL Containers & Algorithms for Python**

Pythonic wrappers around native C++ STL containers and algorithms backed by native [SWIG](https://www.swig.org/) bindings. AlgoKit DS provides familiar C++ STL containers such as `std::vector`,`std::deque`, `std::map`, and `std::unordered_set`, together with native STL algorithms like `sort`, `reverse`, `binary_search`, `lower_bound`, and
`upper_bound`, all through a clean and Pythonic interface.

Unlike most Python data structure libraries, AlgoKit DS executes operations directly on the underlying C++ containers without converting them into Python
lists. You get real `std::vector`,`std::map`, `std::unordered_set`, etc. performance under a small, consistent Python API.

- For Documentation & Visualization:- https://ayush09062004.github.io/algokit-ds-documentation/
- For Benchmark Results:- (Benchmarks.ipynb) in https://github.com/ayush09062004/algokit-ds-documentation

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
- [Benchmarks](#benchmarks)
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

Algorithms operate directly on the underlying native C++ STL containers.

| Python API | STL Equivalent |
|------------|----------------|
| `sort()` | `std::sort` |
| `stable_sort()` | `std::stable_sort` |
| `reverse()` | `std::reverse` |
| `binary_search()` | `std::binary_search` |
| `lower_bound()` | `std::lower_bound` |
| `upper_bound()` | `std::upper_bound` |

## Algorithms

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

| Function | Description |
|-----------|-------------|
| `sort(container)` | Sorts the container in ascending order. |
| `stable_sort(container)` | Stable sorting algorithm. |
| `reverse(container)` | Reverses the container in-place. |
| `binary_search(container,x)` | Returns `True` if the value exists. |
| `lower_bound(container,x)` | Returns the first index not less than `x`. |
| `upper_bound(container,x)` | Returns the first index greater than `x`. |

Algorithms currently support:

- vector
- deque


## Benchmarks

These numbers come from an independent verification notebook that builds
`algokit-ds` from source exactly as the instructions above describe, then
times every operation against an equivalent pure-Python implementation on
identical inputs, with a correctness `assert` baked into every benchmark
function — if a result were wrong, the cell would raise instead of printing
a bogus number. Measured on a Google Colab CPU runtime; absolute times will
vary with the machine, but the relative ratios should be stable.

There are two very different access patterns benchmarked here, and they
give opposite answers on purpose — reporting only one of them would be
misleading.

### 1. Algorithms — one native call runs the whole loop in C++ (n = 500,000)

This is `benchmarks/algorithms_benchmark.py`, covering one representative
algorithm from every category `algokit_ds.algorithms` implements.

| Category | Operation | Python | `algokit_ds` | Speedup | Compared against |
|---|---|---:|---:|---:|---|
| searching | `find` | 0.01195s | 0.00022s | **53.82×** | `list.index()` |
| searching | `count` | 0.00775s | 0.00036s | **21.48×** | `list.count()` |
| searching | `binary_search` + `lower_bound` | 0.00002s | 0.00010s | 0.17× | `bisect` (also C-implemented) |
| min/max | `min_element` | 0.00752s | 0.00060s | **12.59×** | `min()` |
| modification | `remove` | 0.01262s | 0.00147s | **8.61×** | erase-remove idiom vs list comprehension |
| modification | `unique` | 0.07498s | 0.00147s | **51.13×** | consecutive-duplicate removal, pre-sorted data |
| modification | `fill` | 0.01273s | 0.00008s | **153.17×** | Python `for`-loop assignment |
| reordering | `rotate` | 0.00928s | 0.00106s | **8.72×** | slicing |
| reordering | `shuffle` | 0.31605s | 0.00492s | **64.24×** | `random.shuffle()` |
| partitioning | `partition` | 0.15220s | 0.07644s | **1.99×** | two list comprehensions |
| merging | `merge` | 0.20860s | 0.23284s | 0.90× | `sorted(a + b)` |
| set algorithms | `set_union` | 0.20724s | 0.03262s | **6.35×** | `sorted(set(a).union(set(b)))` |
| heap | `make_heap` + `sort_heap` | 0.18008s | 0.08613s | **2.09×** | `sorted()` |
| permutation | `is_permutation` | 0.00284s | 0.13596s | 0.02× | `sorted(a) == sorted(b)` (size-capped) |
| permutation | `next_permutation` | 0.00947s | 0.00918s | 1.03× | single step, fixed small n |
| numeric | `accumulate` | 0.00435s | 0.00063s | **6.90×** | `sum()` |
| numeric | `partial_sum` | 0.01222s | 0.04583s | 0.27× | `itertools.accumulate` |
| numeric | `adjacent_difference` | 0.03530s | 0.04858s | 0.73× | Python list comprehension |

Most algorithms land in the **~5×–150× faster** range. The exceptions
(`merge`, `is_permutation`, `partial_sum`, `adjacent_difference`,
`binary_search`) are all cases where the Python-side baseline is *also*
a tight, C-implemented operation (`bisect`, `sorted()`, `itertools`), or
where the current C++ implementation isn't yet the optimal one for that
op — these are documented here rather than hidden.

### 2. Containers — many small per-call operations from Python (n = 200,000)

This measures the other side of the tradeoff: individual `append`/`[i]`/
membership/insert calls issued one at a time from Python, which is the
access pattern most everyday code actually uses (as opposed to Section 1,
where one native call runs an entire algorithm inside C++).

| Operation | Python | `algokit_ds` | Ratio | Compared against |
|---|---:|---:|---:|---|
| `vector.append` (build N-element container) | 0.00645s | 0.04363s | 0.15× | `list.append` vs `vector.append` |
| `vector` indexed sum (read all N elements) | 0.00785s | 0.08410s | 0.09× | `list[i]` vs `vector[i]` |
| `unordered_set` membership (N inserts + N lookups) | 0.09920s | 0.19005s | 0.52× | `set` vs `unordered_set` |
| `unordered_map` insert + lookup (N keys) | 0.05037s | 0.17614s | 0.29× | `dict` vs `unordered_map` |

**Why these ratios are below 1×, and why that's the honest result:** every
`v.append(x)`, `v[i]`, or `m[k]` call here crosses the Python↔C++ (SWIG)
boundary individually — one marshalling round-trip per element, N times.
That per-call overhead outweighs the raw speed of the underlying `std::`
container at these sizes, so plain Python `list`/`set`/`dict` win when
used this way. `algokit_ds` is fastest when you hand it a whole container
and let one native algorithm (Section 1) run the loop *inside* C++, not
when Python itself drives the loop one call at a time (this section).

### Summary

| Benchmark | What it measures | Typical result |
|---|---|---|
| Algorithms (n=500,000) | One native call runs a whole O(n) algorithm in C++ | **~5×–150× faster** than Python, depending on algorithm |
| Containers (n=200,000) | Many small per-element calls across the Python↔C++ boundary | **~0.1×–0.5×** — plain Python wins at this access pattern |

If your workload can express itself as "build/load a container, then call
one `algokit_ds.algorithms` function on it," you get the native speedup.
If your workload is many individual element-by-element operations driven
from Python, a plain `list`/`set`/`dict` will currently be faster — that's
a property of the SWIG marshalling boundary, not something this benchmark
is trying to talk around.

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
