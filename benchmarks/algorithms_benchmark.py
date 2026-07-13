#!/usr/bin/env python3
"""Benchmarks algokit_ds.algorithms against the equivalent pure-Python
operation, to make the "operates directly on the C++ container, no copy"
claim concrete rather than just asserted.

Covers one representative algorithm from every category algokit_ds.algorithms
implements (searching, min/max, modification, reordering, partitioning,
merging, set algorithms, heap, permutation, numeric) -- not just a
cherry-picked handful. Each entry is registered once via @benchmark(...)
and run through one shared harness, so adding another algorithm to this
file is a single small function, not a copy-pasted block.

Usage:
    python3 benchmarks/algorithms_benchmark.py
    python3 benchmarks/algorithms_benchmark.py --size 2000000
    python3 benchmarks/algorithms_benchmark.py --category heap
"""

from __future__ import annotations

import argparse
import bisect
import random
import time
from dataclasses import dataclass, field

from algokit_ds import vector
from algokit_ds.algorithms import (
    accumulate,
    adjacent_difference,
    binary_search,
    count,
    find,
    fill,
    is_permutation,
    lower_bound,
    make_heap,
    merge,
    min_element,
    next_permutation,
    partial_sum,
    partition,
    remove,
    rotate,
    set_union,
    shuffle,
    sort,
    sort_heap,
    unique,
)


@dataclass
class Benchmark:
    name: str
    category: str
    run: callable
    note: str = ""


REGISTRY: list[Benchmark] = []


def benchmark(name: str, category: str, note: str = ""):
    """Registers a function as a benchmark. The wrapped function takes
    `size` and returns (python_seconds, algokit_ds_seconds); it should
    assert correctness itself before returning, the same way the STL
    algorithms it's timing have no separate correctness check --
    if the assertion fails the benchmark fails, loudly."""

    def decorator(fn):
        REGISTRY.append(Benchmark(name=name, category=category, run=fn, note=note))
        return fn

    return decorator


def timed(fn, *args, **kwargs):
    start = time.perf_counter()
    result = fn(*args, **kwargs)
    return result, time.perf_counter() - start


# ===========================================================================
# Searching
# ===========================================================================


@benchmark("find", "searching", note="vs list.index()")
def bench_find(size: int) -> tuple[float, float]:
    data = [random.randint(0, size) for _ in range(size)]
    needle = data[-1]

    py_list = list(data)
    _, py_time = timed(lambda: py_list.index(needle) if needle in py_list else -1)

    v = vector(int, data)
    _, cpp_time = timed(find, v, needle)
    return py_time, cpp_time


@benchmark("count", "searching", note="vs list.count()")
def bench_count(size: int) -> tuple[float, float]:
    data = [random.randint(0, 10) for _ in range(size)]  # lots of duplicates
    needle = 5

    py_list = list(data)
    result, py_time = timed(py_list.count, needle)

    v = vector(int, data)
    cpp_result, cpp_time = timed(count, v, needle)
    assert cpp_result == result
    return py_time, cpp_time


# ===========================================================================
# Min / max
# ===========================================================================


@benchmark("min_element", "min/max", note="vs min()")
def bench_min_element(size: int) -> tuple[float, float]:
    data = [random.randint(0, size) for _ in range(size)]

    py_list = list(data)
    result, py_time = timed(min, py_list)

    v = vector(int, data)
    idx, cpp_time = timed(min_element, v)
    assert v[idx] == result
    return py_time, cpp_time


# ===========================================================================
# Modification
# ===========================================================================


@benchmark("remove", "modification", note="erase-remove idiom vs list comprehension")
def bench_remove(size: int) -> tuple[float, float]:
    data = [random.randint(0, 4) for _ in range(size)]  # lots of the target value
    target = 2

    py_list = list(data)
    _, py_time = timed(lambda: [x for x in py_list if x != target])

    v = vector(int, data)
    _, cpp_time = timed(remove, v, target)
    assert target not in v
    return py_time, cpp_time


@benchmark("unique", "modification", note="consecutive-duplicate removal on pre-sorted data")
def bench_unique(size: int) -> tuple[float, float]:
    data = sorted(random.randint(0, size // 10) for _ in range(size))

    def py_unique(lst):
        out = []
        for x in lst:
            if not out or out[-1] != x:
                out.append(x)
        return out

    py_list = list(data)
    result, py_time = timed(py_unique, py_list)

    v = vector(int, data)
    _, cpp_time = timed(unique, v)
    assert list(v) == result
    return py_time, cpp_time


@benchmark("fill", "modification", note="vs a Python for-loop assignment")
def bench_fill(size: int) -> tuple[float, float]:
    py_list = [0] * size

    def py_fill(lst):
        for i in range(len(lst)):
            lst[i] = 7

    _, py_time = timed(py_fill, py_list)

    v = vector(int, [0] * size)
    _, cpp_time = timed(fill, v, 7)
    assert all(x == 7 for x in v)
    return py_time, cpp_time


# ===========================================================================
# Reordering
# ===========================================================================


@benchmark("rotate", "reordering", note="vs slicing")
def bench_rotate(size: int) -> tuple[float, float]:
    data = list(range(size))
    n = size // 3

    py_list = list(data)
    result, py_time = timed(lambda: py_list[n:] + py_list[:n])

    v = vector(int, data)
    _, cpp_time = timed(rotate, v, n)
    assert list(v) == result
    return py_time, cpp_time


@benchmark("shuffle", "reordering", note="vs random.shuffle()")
def bench_shuffle(size: int) -> tuple[float, float]:
    data = list(range(size))

    py_list = list(data)
    _, py_time = timed(random.shuffle, py_list)

    v = vector(int, list(data))
    _, cpp_time = timed(shuffle, v, 42)
    assert sorted(v) == data  # still the same elements, just reordered
    return py_time, cpp_time


# ===========================================================================
# Partitioning
# ===========================================================================


@benchmark("partition", "partitioning", note="vs two list comprehensions")
def bench_partition(size: int) -> tuple[float, float]:
    data = [random.randint(0, size) for _ in range(size)]
    predicate = lambda x: x % 2 == 0  # noqa: E731

    py_list = list(data)

    def py_partition(lst):
        return [x for x in lst if predicate(x)] + [x for x in lst if not predicate(x)]

    result, py_time = timed(py_partition, py_list)

    v = vector(int, data)
    point, cpp_time = timed(partition, v, predicate)
    assert sorted(list(v)[:point]) == sorted(x for x in result if predicate(x))
    return py_time, cpp_time


# ===========================================================================
# Merging
# ===========================================================================


@benchmark("merge", "merging", note="two sorted halves, vs sorted(a + b)")
def bench_merge(size: int) -> tuple[float, float]:
    a = sorted(random.randint(0, size) for _ in range(size // 2))
    b = sorted(random.randint(0, size) for _ in range(size // 2))

    py_a, py_b = list(a), list(b)
    result, py_time = timed(lambda: sorted(py_a + py_b))

    va, vb = vector(int, a), vector(int, b)
    merged, cpp_time = timed(merge, va, vb)
    assert list(merged) == result
    return py_time, cpp_time


# ===========================================================================
# Set algorithms
# ===========================================================================


@benchmark("set_union", "set algorithms", note="two sorted ranges, vs sorted(set(a) | set(b))")
def bench_set_union(size: int) -> tuple[float, float]:
    a = sorted(set(random.randint(0, size) for _ in range(size // 2)))
    b = sorted(set(random.randint(0, size) for _ in range(size // 2)))

    py_a, py_b = list(a), list(b)
    result, py_time = timed(lambda: sorted(set(py_a) | set(py_b)))

    va, vb = vector(int, a), vector(int, b)
    union, cpp_time = timed(set_union, va, vb)
    assert list(union) == result
    return py_time, cpp_time


# ===========================================================================
# Heap
# ===========================================================================


@benchmark("heapsort (make_heap + sort_heap)", "heap", note="vs sorted()")
def bench_heap(size: int) -> tuple[float, float]:
    data = [random.randint(0, size) for _ in range(size)]

    py_list = list(data)
    result, py_time = timed(sorted, py_list)

    def cpp_heapsort(v):
        make_heap(v)
        sort_heap(v)

    v = vector(int, data)
    _, cpp_time = timed(cpp_heapsort, v)
    assert list(v) == result
    return py_time, cpp_time


# ===========================================================================
# Permutation
# ===========================================================================


@benchmark(
    "is_permutation",
    "permutation",
    note="two shuffled copies, vs sorted(a) == sorted(b) -- size capped, see comment",
)
def bench_is_permutation(size: int) -> tuple[float, float]:
    # Deliberately NOT scaled by --size like the other benchmarks.
    # std::is_permutation has genuine worst-case O(n^2) complexity on
    # fully-shuffled data (libstdc++ falls back to a nested std::count
    # scan once no trivial prefix/suffix match is found, since there's
    # no requirement to hash), whereas Python's sorted(a) == sorted(b)
    # is O(n log n) via a C-implemented sort. At n=50_000 this
    # genuinely took over a second here -- at the module's own
    # `--size 2000000` usage example, an uncapped version of this
    # benchmark would make the whole script impractically slow. This
    # is a real, honest characteristic of the algorithm, not a bug in
    # the wrapper -- it's exactly why the number is capped rather than
    # hidden.
    n = min(size, 20_000)
    data = list(range(n))
    shuffled = list(data)
    random.shuffle(shuffled)

    py_a, py_b = list(data), list(shuffled)
    result, py_time = timed(lambda: sorted(py_a) == sorted(py_b))

    va, vb = vector(int, data), vector(int, shuffled)
    cpp_result, cpp_time = timed(is_permutation, va, vb)
    assert cpp_result == result
    return py_time, cpp_time


@benchmark("next_permutation", "permutation", note="single step, vs itertools bookkeeping is N/A -- fixed small n")
def bench_next_permutation(size: int) -> tuple[float, float]:
    # This one is deliberately NOT scaled by --size: a single
    # next_permutation() call is O(n) worst case but the interesting
    # comparison is call overhead, not throughput on huge n (nobody
    # calls next_permutation on a million-element container -- (n!)
    # makes that meaningless). Runs a fixed number of iterations instead.
    iterations = 20_000
    base = list(range(8))

    def py_next_permutation(lst):
        # Same algorithm shape as std::next_permutation, in Python, so
        # this is an apples-to-apples "same algorithm, different
        # language" comparison rather than itertools.permutations
        # (which generates ahead of time, a different access pattern).
        i = len(lst) - 2
        while i >= 0 and lst[i] >= lst[i + 1]:
            i -= 1
        if i < 0:
            lst.reverse()
            return False
        j = len(lst) - 1
        while lst[j] <= lst[i]:
            j -= 1
        lst[i], lst[j] = lst[j], lst[i]
        lst[i + 1:] = reversed(lst[i + 1:])
        return True

    py_list = list(base)

    def py_run():
        for _ in range(iterations):
            if not py_next_permutation(py_list):
                py_list[:] = sorted(py_list)

    _, py_time = timed(py_run)

    v = vector(int, list(base))

    def cpp_run():
        for _ in range(iterations):
            next_permutation(v)

    _, cpp_time = timed(cpp_run)
    return py_time, cpp_time


# ===========================================================================
# Numeric
# ===========================================================================


@benchmark("accumulate", "numeric", note="vs sum()")
def bench_accumulate(size: int) -> tuple[float, float]:
    data = [random.random() for _ in range(size)]

    py_list = list(data)
    result, py_time = timed(sum, py_list)

    v = vector(float, data)
    cpp_result, cpp_time = timed(accumulate, v, 0.0)
    assert abs(cpp_result - result) < 1e-6
    return py_time, cpp_time


@benchmark("partial_sum", "numeric", note="running total, vs itertools.accumulate")
def bench_partial_sum(size: int) -> tuple[float, float]:
    import itertools

    data = [random.randint(0, 100) for _ in range(size)]

    py_list = list(data)
    result, py_time = timed(lambda: list(itertools.accumulate(py_list)))

    v = vector(int, data)
    cpp_result, cpp_time = timed(partial_sum, v)
    assert list(cpp_result) == result
    return py_time, cpp_time


@benchmark("adjacent_difference", "numeric", note="vs a Python list comprehension")
def bench_adjacent_difference(size: int) -> tuple[float, float]:
    data = [random.randint(0, size) for _ in range(size)]

    py_list = list(data)

    def py_adjacent_diff(lst):
        return [lst[0]] + [lst[i] - lst[i - 1] for i in range(1, len(lst))]

    result, py_time = timed(py_adjacent_diff, py_list)

    v = vector(int, data)
    cpp_result, cpp_time = timed(adjacent_difference, v)
    assert list(cpp_result) == result
    return py_time, cpp_time


# ===========================================================================
# binary_search / lower_bound (kept from the original, sorted-range search)
# ===========================================================================


@benchmark("binary_search + lower_bound", "searching", note="vs bisect (also C-implemented -- see note below)")
def bench_binary_search(size: int) -> tuple[float, float]:
    data = sorted(random.randint(0, size) for _ in range(size))
    needle = data[size // 2]

    py_list = list(data)
    _, py_time = timed(bisect.bisect_left, py_list, needle)

    v = vector(int, data)
    _, cpp_time = timed(lambda: (binary_search(v, needle), lower_bound(v, needle)))
    return py_time, cpp_time


# ===========================================================================
# Runner
# ===========================================================================


def run_all(size: int, category: str | None = None) -> None:
    selected = [b for b in REGISTRY if category is None or b.category == category]
    if not selected:
        known = sorted({b.category for b in REGISTRY})
        raise SystemExit(f"No benchmarks in category {category!r}. Known categories: {', '.join(known)}")

    current_category = None
    for b in selected:
        if b.category != current_category:
            current_category = b.category
            print(f"\n-- {current_category} " + "-" * (60 - len(current_category)))
        py_time, cpp_time = b.run(size)
        ratio = py_time / cpp_time if cpp_time > 0 else float("inf")
        note = f"  ({b.note})" if b.note else ""
        print(
            f"  {b.name:<32} python: {py_time:9.5f}s   algokit_ds: {cpp_time:9.5f}s   ratio: {ratio:6.2f}x{note}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--size", type=int, default=500_000, help="element count per benchmark")
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument(
        "--category",
        default=None,
        help="only run one category, e.g. --category heap. "
        "Categories: searching, min/max, modification, reordering, "
        "partitioning, merging, set algorithms, heap, permutation, numeric",
    )
    args = parser.parse_args()

    random.seed(args.seed)

    print(f"algokit_ds.algorithms benchmarks (n={args.size})")
    run_all(args.size, args.category)
    print(
        "\nNote: some comparisons (binary_search/bisect, count/list.count, "
        "min_element/min) are against Python's own C-implemented stdlib "
        "equivalents, not a naive Python re-implementation -- those ratios "
        "are the conservative, honest comparison, and can legitimately be "
        "close to 1x or even <1x for small n."
    )
    print(
        "\nNote: algorithms that return a *new* container (merge, "
        "unique_copy, partial_sum, adjacent_difference, set_*, ...) are "
        "not zero-copy end to end the way in-place mutation (sort, "
        "reverse, remove, ...) is: the C++ result comes back as a plain "
        "Python sequence, which then gets rebuilt into a new wrapped "
        "Vector/Deque element by element. That reconstruction shows up "
        "here as real overhead and can legitimately make these slower "
        "than the equivalent Python, especially for smaller n."
    )


if __name__ == "__main__":
    main()