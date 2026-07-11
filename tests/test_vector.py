import pytest

from algokit_ds import vector


def test_default_construct():
    v = vector(int)
    assert len(v) == 0


def test_construct_with_count():
    v = vector(int, 5)
    assert len(v) == 5
    assert list(v) == [0, 0, 0, 0, 0]


def test_construct_with_count_and_value():
    v = vector(int, 3, 7)
    assert list(v) == [7, 7, 7]


def test_construct_from_list():
    v = vector(int, [1, 2, 3])
    assert list(v) == [1, 2, 3]


def test_append_and_push_back_are_equivalent():
    v = vector(int)
    v.append(1)
    v.push_back(2)
    assert list(v) == [1, 2]


def test_pop_and_pop_back():
    v = vector(int, [1, 2, 3])
    assert v.pop() == 3  # Pythonic alias: returns the removed value
    v.pop_back()  # faithful STL name: void, like real std::vector::pop_back
    assert list(v) == [1]


def test_indexing():
    v = vector(int, [1, 2, 3])
    assert v[0] == 1
    v[0] = 99
    assert v[0] == 99


def test_iteration():
    v = vector(int, [1, 2, 3])
    assert [x for x in v] == [1, 2, 3]


def test_float_type():
    v = vector(float, [1.5, 2.5])
    assert list(v) == [1.5, 2.5]


def test_str_type():
    v = vector(str, ["a", "b"])
    assert list(v) == ["a", "b"]


def test_unsupported_type_raises_type_error():
    with pytest.raises(TypeError):
        vector(bool)


def test_repr():
    v = vector(int, [1, 2])
    assert repr(v) == "Vector([1, 2])"
