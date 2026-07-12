import pytest

from algokit_ds import deque, stack, vector
from algokit_ds.algorithms import (
    binary_search,
    lower_bound,
    reverse,
    sort,
    stable_sort,
    upper_bound,
)


def test_sort_mutates_in_place_and_returns_none():
    v = vector(int, [5, 4, 2, 1, 3])
    result = sort(v)
    assert result is None
    assert list(v) == [1, 2, 3, 4, 5]


def test_sort_float_and_str():
    v = vector(float, [3.5, 1.1, 2.2])
    sort(v)
    assert list(v) == [1.1, 2.2, 3.5]

    sv = vector(str, ["banana", "apple", "cherry"])
    sort(sv)
    assert list(sv) == ["apple", "banana", "cherry"]


def test_sort_on_deque():
    d = deque(int, [5, 4, 2, 1, 3])
    sort(d)
    assert list(d) == [1, 2, 3, 4, 5]


def test_stable_sort_matches_sort_for_totally_ordered_data():
    v = vector(int, [5, 4, 2, 1, 3])
    stable_sort(v)
    assert list(v) == [1, 2, 3, 4, 5]


def test_reverse():
    v = vector(int, [1, 2, 3])
    reverse(v)
    assert list(v) == [3, 2, 1]


def test_binary_search():
    v = vector(int, [1, 2, 3, 4, 5])
    assert binary_search(v, 3) is True
    assert binary_search(v, 99) is False


def test_lower_bound_and_upper_bound():
    v = vector(int, [1, 2, 2, 2, 3, 5])
    assert lower_bound(v, 2) == 1
    assert upper_bound(v, 2) == 4
    # value not present: both bounds land on the same insertion point
    assert lower_bound(v, 4) == upper_bound(v, 4) == 5


def test_target_api_example_from_readme():
    v = vector(int, [5, 4, 2, 1, 3])
    sort(v)
    assert list(v) == [1, 2, 3, 4, 5]
    assert binary_search(v, 3)
    assert lower_bound(v, 3) == 2
    assert upper_bound(v, 3) == 3


def test_operates_on_the_same_object_no_copy():
    v = vector(int, [3, 1, 2])
    impl_id_before = id(v._impl)
    sort(v)
    assert id(v._impl) == impl_id_before
    assert list(v) == [1, 2, 3]


def test_unsupported_container_raises_type_error():
    s = stack(int)
    s.push(1)
    with pytest.raises(TypeError):
        sort(s)


def test_raw_swig_object_also_accepted_not_just_the_wrapper():
    v = vector(int, [3, 1, 2])
    sort(v._impl)  # unwrap manually -- _algorithms._unwrap() should no-op here
    assert list(v) == [1, 2, 3]
