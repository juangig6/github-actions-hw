from app import add, multiply, is_even


def test_add():
    assert add(1, 2) == 3
    assert add(-1, 1) == 0


def test_multiply():
    assert multiply(3, 4) == 12
    assert multiply(0, 5) == 0


def test_is_even():
    assert is_even(2) is True
    assert is_even(7) is False
