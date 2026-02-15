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
