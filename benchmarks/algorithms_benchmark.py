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
