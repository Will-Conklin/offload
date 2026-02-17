from offload_backend.usage_store import SQLiteUsageStore


def test_usage_store_defaults_to_sqlite(app):
    assert isinstance(app.state.usage_store, SQLiteUsageStore)


def test_reconcile_uses_authoritative_max(create_session_token, post_usage_reconcile):
    token = create_session_token()

    first = post_usage_reconcile(authorization=f"Bearer {token}", local_count=4)
    assert first.status_code == 200
    assert first.json()["server_count"] == 4

    stale = post_usage_reconcile(authorization=f"Bearer {token}", local_count=2)
    assert stale.status_code == 200
    assert stale.json()["server_count"] == 4


def test_reconcile_conflict_resolution_prefers_higher_count(
    create_session_token,
    post_usage_reconcile,
):
    token = create_session_token()

    current = post_usage_reconcile(authorization=f"Bearer {token}", local_count=3)
    assert current.status_code == 200

    higher = post_usage_reconcile(authorization=f"Bearer {token}", local_count=7)
    assert higher.status_code == 200
    body = higher.json()
    assert body["server_count"] == 7
    assert body["effective_remaining"] == 3


def test_install_id_mismatch_is_rejected(create_session_token, post_usage_reconcile):
    token = create_session_token(install_id="install-12345")

    response = post_usage_reconcile(
        authorization=f"Bearer {token}",
        install_id="different-install",
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "install_id_mismatch"
