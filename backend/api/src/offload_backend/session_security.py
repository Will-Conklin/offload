from __future__ import annotations

NON_PRODUCTION_ENVIRONMENTS = frozenset({"", "dev", "development", "local", "test", "testing"})
PLACEHOLDER_SECRETS = frozenset(
    {
        "changeme",
        "change-me",
        "change-me-please",
        "dev-secret-change-me",
        "offload-session-secret",
        "password",
        "secret",
        "test-secret",
    }
)
MIN_SECRET_LENGTH = 32
MIN_UNIQUE_CHARS = 6


def is_production_like_environment(environment: str) -> bool:
    return environment.strip().lower() not in NON_PRODUCTION_ENVIRONMENTS


def is_strong_session_secret(secret: str) -> bool:
    normalized = secret.strip()
    lowered = normalized.lower()
    if len(normalized) < MIN_SECRET_LENGTH:
        return False
    if lowered in PLACEHOLDER_SECRETS:
        return False
    if len(set(normalized)) < MIN_UNIQUE_CHARS:
        return False
    return True
