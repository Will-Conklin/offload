from __future__ import annotations

from threading import Lock


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
