from offload_backend.dependencies import get_provider
from offload_backend.providers.base import (
    ProviderBreakdownResult,
    ProviderRequestError,
    ProviderTimeout,
)


class FakeProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        _ = (input_text, granularity, context_hints, template_ids)
        return ProviderBreakdownResult(
            steps=[
                {
                    "title": "Step 1",
                    "substeps": [{"title": "Substep 1.1", "substeps": []}],
                }
            ],
            input_tokens=10,
            output_tokens=20,
        )


class TimeoutProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        _ = (input_text, granularity, context_hints, template_ids)
        raise ProviderTimeout("provider timeout")


class FailureProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        _ = (input_text, granularity, context_hints, template_ids)
        raise ProviderRequestError("provider failure")


def create_session(client, install_id: str = "install-12345") -> str:
    response = client.post(
        "/v1/sessions/anonymous",
        json={"install_id": install_id, "app_version": "1.0", "platform": "ios"},
    )
    assert response.status_code == 200
    return response.json()["session_token"]


def test_breakdown_generation_success(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session(client)

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={
            "input_text": "Clean the kitchen",
            "granularity": 3,
            "context_hints": ["home"],
            "template_ids": ["template-1"],
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "openai"
    assert body["usage"]["input_tokens"] == 10
    assert body["steps"][0]["title"] == "Step 1"

    app.dependency_overrides.clear()


def test_breakdown_rejects_missing_opt_in(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session(client)

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": "Clean the kitchen", "granularity": 3},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "consent_required"

    app.dependency_overrides.clear()


def test_breakdown_schema_validation(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session(client)

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": "x", "granularity": 7},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"

    app.dependency_overrides.clear()


def test_breakdown_provider_timeout_mapping(client, app):
    app.dependency_overrides[get_provider] = lambda: TimeoutProvider()
    token = create_session(client)

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": "Clean the kitchen", "granularity": 2},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 504
    assert response.json()["error"]["code"] == "provider_timeout"

    app.dependency_overrides.clear()


def test_breakdown_provider_failure_mapping(client, app):
    app.dependency_overrides[get_provider] = lambda: FailureProvider()
    token = create_session(client)

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": "Clean the kitchen", "granularity": 2},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 502
    assert response.json()["error"]["code"] == "provider_request_failed"

    app.dependency_overrides.clear()


def test_breakdown_request_limit_enforced(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session(client)

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": "x" * 1200, "granularity": 2},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_breakdown_does_not_persist_prompt_content(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session(client)
    prompt = "super-private-prompt-content"

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": prompt, "granularity": 3},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    storage_dump = str(app.state.usage_store.dump())
    assert prompt not in storage_dump

    app.dependency_overrides.clear()
