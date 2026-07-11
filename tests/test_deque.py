from algokit_ds import deque


def test_construct_from_list():
    d = deque(int, [1, 2, 3])
    assert list(d) == [1, 2, 3]


def test_append_and_appendleft():
    d = deque(int)
    d.append(2)
    d.appendleft(1)
    assert list(d) == [1, 2]


def test_pop_and_popleft():
    d = deque(int, [1, 2, 3])
    assert d.pop() == 3
    assert d.popleft() == 1
    assert list(d) == [2]


def test_push_front_push_back_stl_names_still_work():
    d = deque(int)
    d.push_back(2)
    d.push_front(1)
    assert list(d) == [1, 2]


def test_len_and_indexing():
    d = deque(int, [1, 2, 3])
    assert len(d) == 3
    assert d[1] == 2
