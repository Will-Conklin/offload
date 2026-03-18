from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from offload_backend.apple_auth import AppleTokenValidationError, AppleTokenValidator
from offload_backend.dependencies import get_apple_validator


@pytest.fixture
def valid_apple_sub():
    return "apple.sub.test.123456"


@pytest.fixture
def mock_apple_validator(valid_apple_sub):
    """AppleTokenValidator that accepts the token literal 'valid-apple-token' and rejects others."""
    validator = MagicMock(spec=AppleTokenValidator)

    def _validate(token):
        if token == "valid-apple-token":
            return valid_apple_sub
        if token == "expired-apple-token":
            raise AppleTokenValidationError("Apple identity token expired")
        raise AppleTokenValidationError("Invalid Apple identity token")

    validator.validate.side_effect = _validate
    return validator


@pytest.fixture
def auth_client(app, mock_apple_validator):
    """TestClient with the AppleTokenValidator dependency overridden."""
    from fastapi.testclient import TestClient

    app.dependency_overrides[get_apple_validator] = lambda: mock_apple_validator
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.pop(get_apple_validator, None)


def test_sign_in_with_valid_token_returns_session(auth_client, valid_apple_sub):
    response = auth_client.post(
        "/v1/auth/apple",
        json={
            "apple_identity_token": "valid-apple-token",
            "install_id": "install-device-001",
            "display_name": "Alice",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert "session_token" in body
    assert "expires_at" in body
    assert "user_id" in body
    assert isinstance(body["user_id"], str)
    assert len(body["user_id"]) == 36  # UUID


def test_sign_in_twice_same_apple_id_returns_same_user_id(auth_client):
    first = auth_client.post(
        "/v1/auth/apple",
        json={
            "apple_identity_token": "valid-apple-token",
            "install_id": "install-device-001",
        },
    )
    second = auth_client.post(
        "/v1/auth/apple",
        json={
            "apple_identity_token": "valid-apple-token",
            "install_id": "install-device-002",
        },
    )

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["user_id"] == second.json()["user_id"]


def test_sign_in_session_token_contains_user_id_claim(auth_client):
    import os

    from offload_backend.security import TokenManager

    response = auth_client.post(
        "/v1/auth/apple",
        json={
            "apple_identity_token": "valid-apple-token",
            "install_id": "install-device-001",
        },
    )
    assert response.status_code == 200
    session_token = response.json()["session_token"]
    user_id = response.json()["user_id"]

    manager = TokenManager(
        secret=os.environ["OFFLOAD_SESSION_SECRET"],
        issuer=os.environ["OFFLOAD_SESSION_TOKEN_ISSUER"],
        audience=os.environ["OFFLOAD_SESSION_TOKEN_AUDIENCE"],
        active_kid=os.environ["OFFLOAD_SESSION_TOKEN_ACTIVE_KID"],
    )
    claims = manager.decode(session_token)
    assert claims.user_id == user_id
    assert claims.install_id == "install-device-001"


def test_sign_in_with_expired_apple_token_returns_401(auth_client):
    response = auth_client.post(
        "/v1/auth/apple",
        json={
            "apple_identity_token": "expired-apple-token",
            "install_id": "install-device-001",
        },
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_apple_token"


def test_sign_in_with_invalid_apple_token_returns_401(auth_client):
    response = auth_client.post(
        "/v1/auth/apple",
        json={
            "apple_identity_token": "totally-bogus-token",
            "install_id": "install-device-001",
        },
    )

    assert response.status_code == 401


def test_sign_in_anonymous_token_still_valid_after_auth(auth_client, create_session_token):
    """Anonymous tokens must remain valid alongside authenticated tokens."""
    anon_token = create_session_token("install-anon-456")

    response = auth_client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-anon-456", "feature": "breakdown", "local_count": 1},
        headers={"Authorization": f"Bearer {anon_token}"},
    )
    assert response.status_code == 200


def test_sign_in_missing_install_id_returns_422(auth_client):
    response = auth_client.post(
        "/v1/auth/apple",
        json={"apple_identity_token": "valid-apple-token"},
    )
    assert response.status_code == 422
