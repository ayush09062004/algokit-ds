import pytest

from algokit_ds import map, multimap, unordered_map


@pytest.mark.parametrize("factory", [map, unordered_map])
def test_setitem_getitem(factory):
    m = factory(str, int)
    m["a"] = 1
    assert m["a"] == 1


@pytest.mark.parametrize("factory", [map, multimap, unordered_map])
def test_contains_and_len(factory):
    m = factory(int, int)
    m[1] = 10
    assert 1 in m
    assert len(m) == 1


def test_keys_values_items():
    m = map(str, int)
    m["a"] = 1
    m["b"] = 2
    assert set(m.keys()) == {"a", "b"}
    assert set(m.values()) == {1, 2}
    assert set(m.items()) == {("a", 1), ("b", 2)}


def test_int_int_and_str_str_and_mixed_types():
    m1 = map(int, int)
    m1[1] = 2
    assert m1[1] == 2

    m2 = map(str, str)
    m2["a"] = "b"
    assert m2["a"] == "b"

    m3 = map(int, float)
    m3[1] = 2.5
    assert m3[1] == 2.5


def test_unsupported_key_value_combo_raises():
    with pytest.raises(TypeError):
        map(float, float)
