from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime
from threading import Lock
from typing import Protocol


@dataclass(frozen=True)
class SessionRateLimitState:
    count: int
    window_started_at: datetime


class SessionRateLimitExceeded(Exception):
    def __init__(self, *, dimension: str, retry_after_seconds: int):
        self.dimension = dimension
        self.retry_after_seconds = retry_after_seconds
        super().__init__(f"Session rate limit exceeded for {dimension}")


class SessionRateLimiter(Protocol):
    def check(self, *, client_ip: str, install_id: str) -> None: ...


class InMemorySessionRateLimiter:
    def __init__(
        self,
        *,
        limit_per_ip: int,
        limit_per_install: int,
        window_seconds: int,
        now_provider: Callable[[], datetime] | None = None,
    ):
        self._limit_per_ip = limit_per_ip
        self._limit_per_install = limit_per_install
        self._window_seconds = window_seconds
        self._now_provider = now_provider or (lambda: datetime.now(UTC))
        self._ip_windows: dict[str, SessionRateLimitState] = {}
        self._install_windows: dict[str, SessionRateLimitState] = {}
        self._lock = Lock()

    def check(self, *, client_ip: str, install_id: str) -> None:
        now = self._now_provider()
        with self._lock:
            self._ip_windows[client_ip] = self._consume(
                state=self._ip_windows.get(client_ip),
                limit=self._limit_per_ip,
                now=now,
                dimension="ip",
            )
            self._install_windows[install_id] = self._consume(
                state=self._install_windows.get(install_id),
                limit=self._limit_per_install,
                now=now,
                dimension="install_id",
            )

    def _consume(
        self,
        *,
        state: SessionRateLimitState | None,
        limit: int,
        now: datetime,
        dimension: str,
    ) -> SessionRateLimitState:
        if state is None:
            return SessionRateLimitState(count=1, window_started_at=now)

        elapsed = (now - state.window_started_at).total_seconds()
        if elapsed >= self._window_seconds:
            return SessionRateLimitState(count=1, window_started_at=now)

        if state.count >= limit:
            retry_after = max(1, int(self._window_seconds - elapsed))
            raise SessionRateLimitExceeded(
                dimension=dimension,
                retry_after_seconds=retry_after,
            )

        return SessionRateLimitState(
            count=state.count + 1,
            window_started_at=state.window_started_at,
        )
