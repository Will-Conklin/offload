def create_session(client, install_id: str = "install-12345") -> str:
    response = client.post(
        "/v1/sessions/anonymous",
        json={"install_id": install_id, "app_version": "1.0", "platform": "ios"},
    )
    assert response.status_code == 200
    return response.json()["session_token"]


def test_reconcile_uses_authoritative_max(client):
    token = create_session(client)

    first = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 4},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert first.status_code == 200
    assert first.json()["server_count"] == 4

    stale = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 2},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert stale.status_code == 200
    assert stale.json()["server_count"] == 4


def test_reconcile_conflict_resolution_prefers_higher_count(client):
    token = create_session(client)

    current = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 3},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert current.status_code == 200

    higher = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "install-12345", "feature": "breakdown", "local_count": 7},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert higher.status_code == 200
    body = higher.json()
    assert body["server_count"] == 7
    assert body["effective_remaining"] == 3


def test_install_id_mismatch_is_rejected(client):
    token = create_session(client, install_id="install-12345")

    response = client.post(
        "/v1/usage/reconcile",
        json={"install_id": "different-install", "feature": "breakdown", "local_count": 1},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "install_id_mismatch"
