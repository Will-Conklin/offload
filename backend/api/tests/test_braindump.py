from offload_backend.dependencies import get_ai_inference_rate_limiter, get_provider
from offload_backend.providers.base import (
    ProviderBrainDumpResult,
    ProviderRequestError,
    ProviderTimeout,
)
from offload_backend.session_rate_limiter import InMemorySessionRateLimiter


class FakeBrainDumpProvider:
    provider_name = "fake"

    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        raise NotImplementedError

    async def compile_brain_dump(self, *, input_text, context_hints):
        _ = (input_text, context_hints)
        return ProviderBrainDumpResult(
            items=[
                {"title": "Call dentist", "type": "task"},
                {"title": "Party ideas", "type": "idea"},
            ],
            input_tokens=15,
            output_tokens=25,
        )


class TimeoutBrainDumpProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        raise NotImplementedError

    async def compile_brain_dump(self, *, input_text, context_hints):
        _ = (input_text, context_hints)
        raise ProviderTimeout("provider timeout")


class FailureBrainDumpProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        raise NotImplementedError

    async def compile_brain_dump(self, *, input_text, context_hints):
        _ = (input_text, context_hints)
        raise ProviderRequestError("provider failure")


def test_braindump_compile_success(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "I need to call the dentist and I have some party ideas brewing."},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "fake"
    assert body["usage"]["input_tokens"] == 15
    assert len(body["items"]) == 2
    assert body["items"][0]["title"] == "Call dentist"
    assert body["items"][0]["type"] == "task"
    assert body["items"][1]["type"] == "idea"

    app.dependency_overrides.clear()


def test_braindump_rejects_missing_opt_in(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "Some long capture text here."},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "consent_required"

    app.dependency_overrides.clear()


def test_braindump_rejects_missing_auth(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "Some capture."},
        headers={"X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 401

    app.dependency_overrides.clear()


def test_braindump_rejects_expired_token(client, app, create_expired_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_expired_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "Some capture."},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "expired_token"

    app.dependency_overrides.clear()


def test_braindump_rejects_oversized_input(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "x" * 1001},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_braindump_provider_timeout_returns_504(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: TimeoutBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "A long brain dump that takes too long."},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 504
    assert response.json()["error"]["code"] == "provider_timeout"

    app.dependency_overrides.clear()


def test_braindump_provider_failure_returns_502(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FailureBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "A brain dump with a failing provider."},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 502
    assert response.json()["error"]["code"] == "provider_request_failed"

    app.dependency_overrides.clear()


def test_braindump_schema_validation_rejects_empty_input(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": ""},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()


def test_braindump_accepts_context_hints(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={
            "input_text": "Brain dump text with hints.",
            "context_hints": ["work", "personal"],
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200

    app.dependency_overrides.clear()


def test_braindump_rate_limit_throttles_excess_requests(client, app, create_session_token):
    tight_limiter = InMemorySessionRateLimiter(
        limit_per_install=1, limit_per_ip=1000, window_seconds=60
    )
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    app.dependency_overrides[get_ai_inference_rate_limiter] = lambda: tight_limiter
    token = create_session_token()
    headers = {"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"}
    payload = {"input_text": "Brain dump text."}

    assert client.post("/v1/ai/braindump/compile", json=payload, headers=headers).status_code == 200

    response = client.post("/v1/ai/braindump/compile", json=payload, headers=headers)
    assert response.status_code == 429
    assert response.json()["error"]["code"] == "inference_rate_limited"

    app.dependency_overrides.clear()


def test_braindump_rejects_unknown_fields(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeBrainDumpProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/braindump/compile",
        json={"input_text": "A brain dump.", "unexpected_field": "sneaky"},
        headers={"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()
