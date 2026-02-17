from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor

from offload_backend.usage_store import SQLiteUsageStore


def test_sqlite_usage_store_persists_across_restart(tmp_path):
    db_path = tmp_path / "usage.sqlite3"

    first_store = SQLiteUsageStore(db_path=str(db_path))
    first = first_store.reconcile(install_id="install-1", feature="breakdown", local_count=4)
    assert first == 4
    first_store.close()

    second_store = SQLiteUsageStore(db_path=str(db_path))
    second = second_store.reconcile(install_id="install-1", feature="breakdown", local_count=2)
    assert second == 4
    assert second_store.dump() == {("install-1", "breakdown"): 4}
    second_store.close()


def test_sqlite_usage_store_reconcile_is_atomic_under_concurrency(tmp_path):
    db_path = tmp_path / "usage.sqlite3"
    store_a = SQLiteUsageStore(db_path=str(db_path))
    store_b = SQLiteUsageStore(db_path=str(db_path))

    def _reconcile(local_count: int):
        target = store_a if local_count % 2 == 0 else store_b
        return target.reconcile(
            install_id="install-1",
            feature="breakdown",
            local_count=local_count,
        )

    with ThreadPoolExecutor(max_workers=16) as pool:
        list(pool.map(_reconcile, range(0, 50)))

    final_count = store_a.reconcile(install_id="install-1", feature="breakdown", local_count=0)
    assert final_count == 49

    store_a.close()
    store_b.close()
