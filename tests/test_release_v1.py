import pytest

from algokit_ds import (
    vector,
    deque,
    stack,
    queue,
    set,
    multiset,
    unordered_set,
    unordered_multiset,
    map,
    multimap,
    unordered_map,
)


def test_release_v1():

    # ==========================================================
    # VECTOR
    # ==========================================================
    v = vector(int, [1, 2, 3])

    assert len(v) == 3
    assert list(v) == [1, 2, 3]

    # Python API
    v.append(4)
    assert v.pop() == 4

    # STL API
    v.push_back(4)
    assert v.back() == 4
    assert v.front() == 1

    assert v.pop_back() is None
    assert list(v) == [1, 2, 3]

    v[0] = 100
    assert v[0] == 100

    vf = vector(float)
    vf.append(1.5)
    vf.append(2.5)
    assert list(vf) == [1.5, 2.5]

    vs = vector(str)
    vs.append("hello")
    vs.append("world")
    assert list(vs) == ["hello", "world"]

    # ==========================================================
    # DEQUE
    # ==========================================================
    d = deque(int)

    d.append(2)
    d.appendleft(1)

    assert list(d) == [1, 2]

    assert d.pop() == 2
    assert d.popleft() == 1

    d.push_back(2)
    d.push_front(1)

    assert d.front() == 1
    assert d.back() == 2

    assert d.pop_back() is None
    assert d.pop_front() is None

    assert len(d) == 0

    # ==========================================================
    # STACK
    # ==========================================================
    s = stack(int)

    s.push(10)
    s.push(20)
    s.push(30)

    assert len(s) == 3
    assert s.top() == 30

    assert s.pop() == 30
    assert s.pop() == 20
    assert s.pop() == 10

    assert len(s) == 0

    # ==========================================================
    # QUEUE
    # ==========================================================
    q = queue(int)

    q.push(1)
    q.push(2)
    q.push(3)

    assert len(q) == 3
    assert q.front() == 1
    assert q.back() == 3

    assert q.pop() == 1
    assert q.pop() == 2
    assert q.pop() == 3

    assert len(q) == 0

    # ==========================================================
    # SET
    # ==========================================================
    st = set(int)

    st.add(1)
    st.add(1)
    st.add(2)

    assert len(st) == 2
    assert 1 in st
    assert 2 in st

    # ==========================================================
    # MULTISET
    # ==========================================================
    ms = multiset(int)

    ms.add(1)
    ms.add(1)
    ms.add(2)

    assert len(ms) == 3

    # ==========================================================
    # UNORDERED SET
    # ==========================================================
    us = unordered_set(int)

    us.add(10)
    us.add(10)
    us.add(20)

    assert len(us) == 2

    # ==========================================================
    # UNORDERED MULTISET
    # ==========================================================
    ums = unordered_multiset(int)

    ums.add(5)
    ums.add(5)

    assert len(ums) == 2

    # ==========================================================
    # MAP
    # ==========================================================
    m = map(str, int)

    m["one"] = 1
    m["two"] = 2

    assert m["one"] == 1
    assert m["two"] == 2
    assert len(m) == 2

    assert "one" in m
    assert "two" in m

    # ==========================================================
    # MULTIMAP
    # ==========================================================
    mm = multimap(str, int)

    mm["x"] = 1
    mm["x"] = 2

    assert len(mm) == 2

    # ==========================================================
    # UNORDERED MAP
    # ==========================================================
    um = unordered_map(str, int)

    um["hello"] = 100
    um["world"] = 200

    assert um["hello"] == 100
    assert um["world"] == 200

    # ==========================================================
    # EQUALITY
    # ==========================================================
    a = vector(int, [1, 2, 3])
    b = vector(int, [1, 2, 3])

    assert a == b

    b.append(4)

    assert a != b

    # ==========================================================
    # ITERATION
    # ==========================================================
    assert sum(vector(int, [1, 2, 3, 4])) == 10

    # ==========================================================
    # STRESS TEST
    # ==========================================================
    stress = vector(int)

    for i in range(10000):
        stress.append(i)

    assert len(stress) == 10000

    for i in reversed(range(10000)):
        assert stress.pop() == i

    assert len(stress) == 0

    # ==========================================================
    # UNSUPPORTED TYPES
    # ==========================================================
    with pytest.raises(TypeError):
        vector(bool)

    with pytest.raises(TypeError):
        set(bool)

    with pytest.raises(TypeError):
        multiset(bool)

    with pytest.raises(TypeError):
        unordered_set(bool)

    with pytest.raises(TypeError):
        unordered_multiset(bool)

    with pytest.raises(TypeError):
        map(bool, int)

    with pytest.raises(TypeError):
        unordered_map(bool, int)