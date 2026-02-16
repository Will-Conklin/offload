import pytest
from pydantic import ValidationError

from offload_backend.config import Settings


def test_session_secret_default_is_not_static(monkeypatch):
    monkeypatch.delenv("OFFLOAD_SESSION_SECRET", raising=False)

    first = Settings().session_secret
    second = Settings().session_secret

    assert first
    assert second
    assert first != "dev-secret-change-me"
    assert second != "dev-secret-change-me"
    assert first != second


def test_production_requires_explicit_session_secret(monkeypatch):
    monkeypatch.setenv("OFFLOAD_ENVIRONMENT", "production")
    monkeypatch.delenv("OFFLOAD_SESSION_SECRET", raising=False)

    with pytest.raises(ValidationError, match="OFFLOAD_SESSION_SECRET"):
        Settings()


@pytest.mark.parametrize(
    "secret",
    [
        "dev-secret-change-me",
        "test-secret",
        "short-secret",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    ],
)
def test_production_rejects_weak_or_placeholder_session_secret(monkeypatch, secret):
    monkeypatch.setenv("OFFLOAD_ENVIRONMENT", "production")
    monkeypatch.setenv("OFFLOAD_SESSION_SECRET", secret)

    with pytest.raises(ValidationError, match="OFFLOAD_SESSION_SECRET"):
        Settings()


def test_production_accepts_strong_explicit_session_secret(monkeypatch):
    strong_secret = "d4f0b11af3e742e5b006f9f98f4f9c2f-v1-rotatable"
    monkeypatch.setenv("OFFLOAD_ENVIRONMENT", "production")
    monkeypatch.setenv("OFFLOAD_SESSION_SECRET", strong_secret)

    settings = Settings()

    assert settings.session_secret == strong_secret


def test_session_signing_keys_default_to_active_kid(monkeypatch):
    monkeypatch.setenv("OFFLOAD_SESSION_SECRET", "test-secret")
    monkeypatch.setenv("OFFLOAD_SESSION_TOKEN_ACTIVE_KID", "test-kid")
    monkeypatch.delenv("OFFLOAD_SESSION_SIGNING_KEYS", raising=False)

    settings = Settings()

    assert settings.session_signing_keys == {"test-kid": "test-secret"}


def test_rejects_active_kid_missing_from_signing_keys(monkeypatch):
    monkeypatch.setenv("OFFLOAD_SESSION_TOKEN_ACTIVE_KID", "active-kid")
    monkeypatch.setenv("OFFLOAD_SESSION_SIGNING_KEYS", '{"other-kid":"test-secret"}')

    with pytest.raises(ValidationError, match="OFFLOAD_SESSION_TOKEN_ACTIVE_KID"):
        Settings()


def test_production_rejects_weak_signing_keys(monkeypatch):
    strong_secret = "d4f0b11af3e742e5b006f9f98f4f9c2f-v1-rotatable"
    monkeypatch.setenv("OFFLOAD_ENVIRONMENT", "production")
    monkeypatch.setenv("OFFLOAD_SESSION_SECRET", strong_secret)
    monkeypatch.setenv("OFFLOAD_SESSION_TOKEN_ACTIVE_KID", "test-kid")
    monkeypatch.setenv("OFFLOAD_SESSION_SIGNING_KEYS", '{"test-kid":"test-secret"}')

    with pytest.raises(ValidationError, match="OFFLOAD_SESSION_SIGNING_KEYS"):
        Settings()
