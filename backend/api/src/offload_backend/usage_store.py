from __future__ import annotations

import sqlite3
from pathlib import Path
from threading import Lock
from typing import Protocol


class UsageStore(Protocol):
    def reconcile(self, *, install_id: str, feature: str, local_count: int) -> int: ...
    def dump(self) -> dict[tuple[str, str], int]: ...
    def close(self) -> None: ...


class InMemoryUsageStore:
    def __init__(self):
        self._counts: dict[tuple[str, str], int] = {}
        self._lock = Lock()

    def reconcile(self, *, install_id: str, feature: str, local_count: int) -> int:
        key = (install_id, feature)
        with self._lock:
            current = self._counts.get(key, 0)
            reconciled = max(current, local_count)
            self._counts[key] = reconciled
            return reconciled

    def dump(self) -> dict[tuple[str, str], int]:
        with self._lock:
            return dict(self._counts)

    def close(self) -> None:
        return None


class SQLiteUsageStore:
    def __init__(self, *, db_path: str):
        self._lock = Lock()
        self._connection = self._open_connection(db_path=db_path)
        self._bootstrap_schema()

    def _open_connection(self, *, db_path: str) -> sqlite3.Connection:
        if db_path != ":memory:":
            Path(db_path).expanduser().resolve().parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(db_path, check_same_thread=False)
        connection.execute("PRAGMA journal_mode=WAL")
        connection.execute("PRAGMA busy_timeout=5000")
        return connection

    def _bootstrap_schema(self) -> None:
        with self._lock:
            self._connection.execute(
                """
                CREATE TABLE IF NOT EXISTS usage_counts (
                    install_id TEXT NOT NULL,
                    feature TEXT NOT NULL,
                    count INTEGER NOT NULL,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (install_id, feature)
                )
                """,
            )
            self._connection.commit()

    def _reconcile_transaction(self, *, install_id: str, feature: str, local_count: int) -> int:
        self._connection.execute("BEGIN IMMEDIATE")
        self._connection.execute(
            """
            INSERT INTO usage_counts (install_id, feature, count)
            VALUES (?, ?, ?)
            ON CONFLICT (install_id, feature)
            DO UPDATE SET
                count = MAX(usage_counts.count, excluded.count),
                updated_at = CURRENT_TIMESTAMP
            """,
            (install_id, feature, local_count),
        )
        row = self._connection.execute(
            "SELECT count FROM usage_counts WHERE install_id = ? AND feature = ?",
            (install_id, feature),
        ).fetchone()
        self._connection.commit()
        if row is None:
            raise RuntimeError("failed to reconcile usage count")
        return int(row[0])

    def reconcile(self, *, install_id: str, feature: str, local_count: int) -> int:
        with self._lock:
            try:
                return self._reconcile_transaction(
                    install_id=install_id,
                    feature=feature,
                    local_count=local_count,
                )
            except Exception:
                self._connection.rollback()
                raise

    def dump(self) -> dict[tuple[str, str], int]:
        with self._lock:
            rows = self._connection.execute(
                "SELECT install_id, feature, count FROM usage_counts",
            ).fetchall()
            return {
                (str(install_id), str(feature)): int(count)
                for install_id, feature, count in rows
            }

    def close(self) -> None:
        with self._lock:
            self._connection.close()
