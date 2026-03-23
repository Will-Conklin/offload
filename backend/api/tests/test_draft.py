from conftest import FailureAIProvider, FakeAIProvider, TimeoutAIProvider

from offload_backend.dependencies import get_provider


def test_draft_communication_success(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={
            "input_text": "Follow up about the project deadline",
            "channel": "email",
            "contact_name": "Jane Doe",
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "fake"
    assert body["draft_text"] == "Hi! I wanted to reach out about this."
    assert body["tone"] == "friendly"
    assert body["usage"]["input_tokens"] == 30
    assert body["usage"]["output_tokens"] == 50
    assert body["latency_ms"] >= 0

    app.dependency_overrides.clear()


def test_draft_communication_without_contact_name(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={
            "input_text": "Remind about meeting",
            "channel": "text",
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["draft_text"] == "Hi! I wanted to reach out about this."

    app.dependency_overrides.clear()


def test_draft_rejects_missing_opt_in(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={"input_text": "Hello", "channel": "call"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "consent_required"

    app.dependency_overrides.clear()


def test_draft_rejects_missing_auth(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()

    response = client.post(
        "/v1/ai/communication/draft",
        json={"input_text": "Hello", "channel": "call"},
        headers={"X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 401

    app.dependency_overrides.clear()


def test_draft_rejects_oversized_request(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={
            "input_text": "x" * 1001,
            "channel": "email",
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_draft_provider_timeout(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: TimeoutAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={"input_text": "Hello", "channel": "text"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 504

    app.dependency_overrides.clear()


def test_draft_provider_failure(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FailureAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={"input_text": "Hello", "channel": "call"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 502

    app.dependency_overrides.clear()


def test_draft_validation_rejects_empty_text(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/communication/draft",
        json={"input_text": "", "channel": "email"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()
