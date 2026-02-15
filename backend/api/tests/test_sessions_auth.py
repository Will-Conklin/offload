from datetime import UTC, datetime, timedelta

from offload_backend.security import SessionClaims, TokenManager


def create_session(client, install_id: str = "install-12345") -> str:
    response = client.post(
        "/v1/sessions/anonymous",
        json={
            "install_id": install_id,
            "app_version": "1.0",
            "platform": "ios",
        },
    )
    assert response.status_code == 200
    return response.json()["session_token"]


def test_session_issuance_returns_token_and_expiry(client):
    response = client.post(
        "/v1/sessions/anonymous",
        json={"install_id": "install-12345", "app_version": "1.0", "platform": "ios"},
    )

    assert response.status_code == 200
    body = response.json()
    assert isinstance(body["session_token"], str)
    assert body["session_token"]
    assert body["expires_at"]


def test_missing_token_is_rejected(client):
    response = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 1},
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"


def test_invalid_token_is_rejected(client):
    response = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 1},
        headers={"Authorization": "Bearer invalid-token"},
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


def test_expired_token_is_rejected(client):
    manager = TokenManager(secret="test-secret")
    expired_claims = SessionClaims(
        install_id="install-12345",
        expires_at=datetime.now(UTC) - timedelta(seconds=1),
    )
    expired_token = manager.encode(expired_claims)

    response = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 1},
        headers={"Authorization": f"Bearer {expired_token}"},
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "expired_token"


def test_valid_token_allows_protected_endpoint(client):
    token = create_session(client)

    response = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 3},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()["server_count"] == 3
