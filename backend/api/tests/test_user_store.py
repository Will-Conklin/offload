from __future__ import annotations

import pytest

from offload_backend.user_store import SQLiteUserStore


@pytest.fixture
def store():
    s = SQLiteUserStore(db_path=":memory:")
    yield s
    s.close()


def test_upsert_creates_new_user(store):
    record = store.upsert_by_apple_id(
        apple_user_id="apple.sub.123",
        install_id="install-abc",
        display_name="Test User",
    )

    assert record.apple_user_id == "apple.sub.123"
    assert record.install_id == "install-abc"
    assert record.display_name == "Test User"
    assert len(record.user_id) == 36  # UUID format


def test_upsert_same_apple_id_returns_same_user_id(store):
    first = store.upsert_by_apple_id(
        apple_user_id="apple.sub.123",
        install_id="install-abc",
        display_name="Test User",
    )
    second = store.upsert_by_apple_id(
        apple_user_id="apple.sub.123",
        install_id="install-xyz",  # different install
        display_name="Updated Name",
    )

    assert first.user_id == second.user_id
    assert second.install_id == "install-xyz"
    assert second.display_name == "Updated Name"


def test_upsert_preserves_display_name_when_none_provided(store):
    store.upsert_by_apple_id(
        apple_user_id="apple.sub.456",
        install_id="install-abc",
        display_name="Original Name",
    )
    updated = store.upsert_by_apple_id(
        apple_user_id="apple.sub.456",
        install_id="install-abc",
        display_name=None,  # should not overwrite
    )

    assert updated.display_name == "Original Name"


def test_get_by_apple_id_returns_record(store):
    store.upsert_by_apple_id(
        apple_user_id="apple.sub.789",
        install_id="install-abc",
        display_name=None,
    )

    record = store.get_by_apple_id("apple.sub.789")
    assert record is not None
    assert record.apple_user_id == "apple.sub.789"
    assert record.display_name is None


def test_get_by_apple_id_returns_none_for_missing(store):
    assert store.get_by_apple_id("nonexistent") is None


def test_different_apple_ids_produce_different_user_ids(store):
    a = store.upsert_by_apple_id(
        apple_user_id="apple.sub.aaa",
        install_id="install-1",
        display_name=None,
    )
    b = store.upsert_by_apple_id(
        apple_user_id="apple.sub.bbb",
        install_id="install-2",
        display_name=None,
    )

    assert a.user_id != b.user_id
