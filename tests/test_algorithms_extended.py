import pytest

from algokit_ds import deque, stack, vector
from algokit_ds.algorithms import (
    accumulate,
    adjacent_difference,
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
    swap_ranges,
    unique,
    unique_copy,
)


# ===========================================================================
# Searching
# ===========================================================================


def test_find_and_find_if():
    v = vector(int, [10, 20, 30, 40])
    assert find(v, 30) == 2
    assert find(v, 99) is None
    assert find_if(v, lambda x: x > 25) == 2
    assert find_if(v, lambda x: x > 1000) is None


def test_count_and_count_if():
    v = vector(int, [1, 2, 2, 3, 2])
    assert count(v, 2) == 3
    assert count_if(v, lambda x: x % 2 == 0) == 3


# ===========================================================================
# Min / max
# ===========================================================================


def test_min_max_element():
    v = vector(int, [5, 1, 9, 3])
    assert min_element(v) == 1
    assert max_element(v) == 2
    assert minmax_element(v) == (1, 2)


def test_min_element_empty_raises_index_error():
    with pytest.raises(IndexError):
        min_element(vector(int, []))
    with pytest.raises(IndexError):
        max_element(vector(int, []))
    with pytest.raises(IndexError):
        minmax_element(vector(int, []))


# ===========================================================================
# Modification
# ===========================================================================


def test_replace_and_replace_if():
    v = vector(int, [1, 2, 2, 3])
    replace(v, 2, 99)
    assert list(v) == [1, 99, 99, 3]

    v2 = vector(int, [1, 2, 3, 4])
    replace_if(v2, lambda x: x % 2 == 0, 0)
    assert list(v2) == [1, 0, 3, 0]


def test_remove_and_remove_if_actually_shrink():
    v = vector(int, [1, 2, 2, 3])
    remove(v, 2)
    assert list(v) == [1, 3]
    assert len(v) == 2

    v2 = vector(int, [1, 2, 3, 4, 5])
    remove_if(v2, lambda x: x % 2 == 0)
    assert list(v2) == [1, 3, 5]


def test_unique_and_unique_copy():
    v = vector(int, [1, 1, 2, 2, 3])
    unique(v)
    assert list(v) == [1, 2, 3]

    v2 = vector(int, [1, 1, 2, 2, 3])
    result = unique_copy(v2)
    assert list(result) == [1, 2, 3]
    assert list(v2) == [1, 1, 2, 2, 3]  # untouched
    assert type(result).__name__ == "Vector"


def test_fill_and_fill_n():
    v = vector(int, [0, 0, 0])
    fill(v, 7)
    assert list(v) == [7, 7, 7]

    v2 = vector(int, [0, 0, 0])
    fill_n(v2, 2, 1)
    assert list(v2) == [1, 1, 0]


def test_fill_n_out_of_range_raises_index_error():
    with pytest.raises(IndexError):
        fill_n(vector(int, [1, 2]), 5, 0)


def test_generate_and_generate_n():
    values = iter([1, 2, 3])
    v = vector(int, [0, 0, 0])
    generate(v, lambda: next(values))
    assert list(v) == [1, 2, 3]

    values2 = iter([9, 9])
    v2 = vector(int, [0, 0, 0])
    generate_n(v2, 2, lambda: next(values2))
    assert list(v2) == [9, 9, 0]


def test_swap_ranges_overlapping_prefix_only():
    a = vector(int, [1, 2, 3])
    b = vector(int, [9, 9, 9, 9])
    swap_ranges(a, b)
    assert list(a) == [9, 9, 9]
    assert list(b) == [1, 2, 3, 9]


# ===========================================================================
# Reordering
# ===========================================================================


def test_rotate_and_rotate_copy():
    v = vector(int, [1, 2, 3, 4, 5])
    rotate(v, 2)
    assert list(v) == [3, 4, 5, 1, 2]

    v2 = vector(int, [1, 2, 3, 4, 5])
    result = rotate_copy(v2, 2)
    assert list(result) == [3, 4, 5, 1, 2]
    assert list(v2) == [1, 2, 3, 4, 5]


def test_rotate_out_of_range_raises_index_error():
    with pytest.raises(IndexError):
        rotate(vector(int, [1, 2, 3]), 10)


def test_shuffle_is_deterministic_with_a_seed():
    v1 = vector(int, list(range(30)))
    shuffle(v1, seed=42)
    v2 = vector(int, list(range(30)))
    shuffle(v2, seed=42)
    assert list(v1) == list(v2)
    assert list(v1) != list(range(30))
    assert sorted(v1) == list(range(30))


# ===========================================================================
# Partitioning
# ===========================================================================


def test_partition():
    v = vector(int, [1, 2, 3, 4, 5, 6])
    point = partition(v, lambda x: x % 2 == 0)
    assert point == 3
    assert sorted(list(v)[:point]) == [2, 4, 6]
    assert sorted(list(v)[point:]) == [1, 3, 5]


def test_stable_partition_preserves_relative_order():
    v = vector(int, [1, 2, 3, 4, 5, 6])
    point = stable_partition(v, lambda x: x % 2 == 0)
    assert list(v)[:point] == [2, 4, 6]
    assert list(v)[point:] == [1, 3, 5]


def test_partition_copy():
    v = vector(int, [1, 2, 3, 4, 5, 6])
    matched, unmatched = partition_copy(v, lambda x: x % 2 == 0)
    assert list(matched) == [2, 4, 6]
    assert list(unmatched) == [1, 3, 5]
    assert list(v) == [1, 2, 3, 4, 5, 6]  # untouched


def test_is_partitioned_and_partition_point():
    assert is_partitioned(vector(int, [2, 4, 1, 3]), lambda x: x % 2 == 0)
    assert not is_partitioned(vector(int, [2, 1, 4, 3]), lambda x: x % 2 == 0)
    assert partition_point(vector(int, [2, 4, 6, 1, 3]), lambda x: x % 2 == 0) == 3


# ===========================================================================
# Merging
# ===========================================================================


def test_merge():
    result = merge(vector(int, [1, 3, 5]), vector(int, [2, 4, 6]))
    assert list(result) == [1, 2, 3, 4, 5, 6]
    assert type(result).__name__ == "Vector"


def test_merge_requires_same_type():
    with pytest.raises(TypeError):
        merge(vector(int, [1, 2]), vector(str, ["a"]))


def test_inplace_merge():
    v = vector(int, [1, 3, 5, 2, 4, 6])
    inplace_merge(v, 3)
    assert list(v) == [1, 2, 3, 4, 5, 6]


# ===========================================================================
# Set algorithms
# ===========================================================================


def test_set_algorithms():
    a, b = vector(int, [1, 2, 3, 4]), vector(int, [3, 4, 5, 6])
    assert list(set_union(a, b)) == [1, 2, 3, 4, 5, 6]
    assert list(set_intersection(a, b)) == [3, 4]
    assert list(set_difference(a, b)) == [1, 2]
    assert list(set_symmetric_difference(a, b)) == [1, 2, 5, 6]


def test_includes():
    assert includes(vector(int, [1, 2, 3, 4, 5]), vector(int, [2, 4]))
    assert not includes(vector(int, [1, 2, 3]), vector(int, [4]))


# ===========================================================================
# Heap
# ===========================================================================


def test_heap_roundtrip():
    h = vector(int, [3, 1, 4, 1, 5, 9, 2, 6])
    make_heap(h)
    assert is_heap(h)

    h.append(100)
    push_heap(h)
    assert is_heap(h)
    assert h[0] == 100

    pop_heap(h)
    top = h.pop()
    assert top == 100
    assert is_heap(h)

    sort_heap(h)
    assert list(h) == sorted([3, 1, 4, 1, 5, 9, 2, 6])


def test_is_heap_until():
    assert is_heap_until(vector(int, [9, 5, 4, 1, 1, 3])) == 6
    assert is_heap_until(vector(int, [1, 2, 3])) == 1


# ===========================================================================
# Permutation
# ===========================================================================


def test_next_and_prev_permutation():
    v = vector(int, [1, 2, 3])
    assert next_permutation(v) is True
    assert list(v) == [1, 3, 2]

    v2 = vector(int, [3, 2, 1])
    assert next_permutation(v2) is False
    assert list(v2) == [1, 2, 3]  # wraps to the first permutation

    v3 = vector(int, [1, 2, 3])
    assert prev_permutation(v3) is False
    assert list(v3) == [3, 2, 1]  # wraps to the last permutation


def test_is_permutation():
    assert is_permutation(vector(int, [1, 2, 3]), vector(int, [3, 1, 2]))
    assert not is_permutation(vector(int, [1, 2, 3]), vector(int, [1, 2, 4]))


# ===========================================================================
# Numeric
# ===========================================================================


def test_accumulate():
    assert accumulate(vector(int, [1, 2, 3, 4]), 0) == 10
    assert accumulate(vector(str, ["a", "b", "c"]), "") == "abc"


def test_adjacent_difference_and_partial_sum():
    v = vector(int, [1, 2, 4, 7])
    assert list(adjacent_difference(v)) == [1, 1, 2, 3]
    assert list(partial_sum(v)) == [1, 3, 7, 14]


def test_inner_product():
    a, b = vector(int, [1, 2, 3]), vector(int, [4, 5, 6])
    assert inner_product(a, b, 0) == 32


def test_iota():
    v = vector(int, [0, 0, 0, 0])
    iota(v, 5)
    assert list(v) == [5, 6, 7, 8]


# ===========================================================================
# Cross-cutting: deque coverage, exception handling, container restrictions
# ===========================================================================


def test_works_on_deque_too():
    d = deque(int, [5, 3, 1, 4])
    sort(d)
    assert list(d) == [1, 3, 4, 5]

    result = merge(deque(int, [1, 3]), deque(int, [2, 4]))
    assert list(result) == [1, 2, 3, 4]
    assert type(result).__name__ == "Deque"


def test_predicate_exception_propagates_unchanged():
    class MyError(ValueError):
        pass

    def bad_predicate(x):
        raise MyError("boom")

    with pytest.raises(MyError, match="boom"):
        find_if(vector(int, [1, 2, 3]), bad_predicate)


def test_unsupported_container_raises_type_error():
    s = stack(int)
    s.push(1)
    with pytest.raises(TypeError):
        sort(s)
    with pytest.raises(TypeError):
        find(s, 1)
