from algokit_ds import queue, stack


def test_stack_push_pop_top():
    s = stack(int)
    s.push(1)
    s.push(2)
    assert s.top() == 2
    assert s.pop() == 2
    assert s.top() == 1


def test_stack_len_and_empty():
    s = stack(int)
    assert len(s) == 0
    assert s.empty()
    s.push(1)
    assert len(s) == 1
    assert not s.empty()


def test_queue_push_pop_front_back():
    q = queue(int)
    q.push(1)
    q.push(2)
    assert q.front() == 1
    assert q.back() == 2
    assert q.pop() == 1
    assert q.front() == 2


def test_queue_len_and_empty():
    q = queue(int)
    assert len(q) == 0
    q.push(1)
    assert len(q) == 1
