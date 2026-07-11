import pytest

from algokit_ds import multiset, set, unordered_multiset, unordered_set


@pytest.mark.parametrize("factory", [set, unordered_set])
def test_no_duplicates(factory):
    s = factory(int)
    s.add(1)
    s.add(1)
    assert len(s) == 1


@pytest.mark.parametrize("factory", [multiset, unordered_multiset])
def test_duplicates_allowed(factory):
    s = factory(int)
    s.add(1)
    s.add(1)
    assert len(s) == 2


@pytest.mark.parametrize("factory", [set, multiset, unordered_set, unordered_multiset])
def test_membership_and_unified_add_api(factory):
    s = factory(str)
    s.add("x")
    assert "x" in s
    assert "y" not in s


@pytest.mark.parametrize("factory", [set, multiset, unordered_set, unordered_multiset])
def test_iteration(factory):
    s = factory(int)
    s.add(1)
    s.add(2)
    assert set_of(s) == {1, 2}


def set_of(container):
    return {x for x in container}
