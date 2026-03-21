from offload_backend.dependencies import (
    get_ai_inference_rate_limiter,
    get_provider,
    get_usage_store,
)
from offload_backend.providers.base import (
    ProviderBreakdownResult,
    ProviderRequestError,
    ProviderTimeout,
)
from offload_backend.session_rate_limiter import InMemorySessionRateLimiter
from offload_backend.usage_store import InMemoryUsageStore


class FakeProvider:
    provider_name = "fake"

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


def test_breakdown_generation_success(client, app, create_session_token, make_breakdown_payload):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(context_hints=["home"], template_ids=["template-1"]),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "fake"
    assert body["usage"]["input_tokens"] == 10
    assert body["steps"][0]["title"] == "Step 1"

    app.dependency_overrides.clear()


def test_breakdown_rejects_missing_opt_in(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "consent_required"

    app.dependency_overrides.clear()


def test_breakdown_schema_validation(client, app, create_session_token, make_breakdown_payload):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(input_text="x", granularity=7),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"

    app.dependency_overrides.clear()


def test_breakdown_provider_timeout_mapping(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: TimeoutProvider()
    token = create_session_token()

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


def test_breakdown_accepts_list_field_length_boundary(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(
            input_text="x",
            context_hints=["h"] * 32,
            template_ids=["t"] * 32,
        ),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    app.dependency_overrides.clear()


def test_breakdown_rejects_list_field_length_over_limit(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(context_hints=["h"] * 33),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"
    app.dependency_overrides.clear()


def test_breakdown_rejects_context_hint_element_too_long(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(context_hints=["x" * 281]),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"
    app.dependency_overrides.clear()


def test_breakdown_rejects_template_id_element_too_long(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(template_ids=["x" * 129]),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"
    app.dependency_overrides.clear()


def test_breakdown_provider_failure_mapping(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FailureProvider()
    token = create_session_token()

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


def test_breakdown_request_limit_enforced(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(input_text="x" * 1200, granularity=2),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_breakdown_request_limit_counts_context_hints_and_template_ids(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(
            input_text="x",
            granularity=2,
            context_hints=["a" * 280, "b" * 280, "c" * 280],
            template_ids=["d" * 128, "e" * 128],
        ),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_breakdown_does_not_persist_prompt_content(
    client,
    app,
    create_session_token,
    make_breakdown_payload,
):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()
    prompt = "super-private-prompt-content"

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(input_text=prompt),
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    storage_dump = str(app.state.usage_store.dump())
    assert prompt not in storage_dump

    app.dependency_overrides.clear()


def test_breakdown_rate_limit_throttles_excess_requests(
    client, app, create_session_token, make_breakdown_payload
):
    tight_limiter = InMemorySessionRateLimiter(
        limit_per_install=1, limit_per_ip=1000, window_seconds=60
    )
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    app.dependency_overrides[get_ai_inference_rate_limiter] = lambda: tight_limiter
    token = create_session_token()
    headers = {"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"}

    assert (
        client.post(
            "/v1/ai/breakdown/generate",
            json=make_breakdown_payload(),
            headers=headers,
        ).status_code
        == 200
    )

    response = client.post(
        "/v1/ai/breakdown/generate", json=make_breakdown_payload(), headers=headers
    )
    assert response.status_code == 429
    assert response.json()["error"]["code"] == "inference_rate_limited"

    app.dependency_overrides.clear()


def test_breakdown_quota_exhausted_returns_429(
    client, app, create_session_token, make_breakdown_payload
):
    # Pre-fill usage to exactly the quota (10 in test env)
    exhausted_store = InMemoryUsageStore()
    for _ in range(10):
        exhausted_store.increment(install_id="install-12345", feature="breakdown")
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    app.dependency_overrides[get_usage_store] = lambda: exhausted_store
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(),
        headers={"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 429
    assert response.json()["error"]["code"] == "quota_exceeded"

    app.dependency_overrides.clear()


def test_breakdown_quota_not_exhausted_increments(
    client, app, create_session_token, make_breakdown_payload
):
    under_quota_store = InMemoryUsageStore()
    for _ in range(9):
        under_quota_store.increment(install_id="install-12345", feature="breakdown")
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    app.dependency_overrides[get_usage_store] = lambda: under_quota_store
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(),
        headers={"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 200
    assert under_quota_store.get_total_count(
        install_id="install-12345", features=["breakdown", "braindump", "decide"]
    ) == 10

    app.dependency_overrides.clear()


def test_breakdown_provider_error_does_not_increment(
    client, app, create_session_token, make_breakdown_payload
):
    store = InMemoryUsageStore()
    app.dependency_overrides[get_provider] = lambda: TimeoutProvider()
    app.dependency_overrides[get_usage_store] = lambda: store
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(),
        headers={"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 504
    assert store.get_total_count(install_id="install-12345", features=["breakdown"]) == 0

    app.dependency_overrides.clear()


def test_breakdown_quota_is_shared_across_features(
    client, app, create_session_token, make_breakdown_payload
):
    # Quota filled entirely by braindump/decide, not breakdown
    cross_feature_store = InMemoryUsageStore()
    for _ in range(6):
        cross_feature_store.increment(install_id="install-12345", feature="braindump")
    for _ in range(4):
        cross_feature_store.increment(install_id="install-12345", feature="decide")
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    app.dependency_overrides[get_usage_store] = lambda: cross_feature_store
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json=make_breakdown_payload(),
        headers={"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 429
    assert response.json()["error"]["code"] == "quota_exceeded"

    app.dependency_overrides.clear()


def test_breakdown_rejects_unknown_fields(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/breakdown/generate",
        json={"input_text": "Clean the kitchen", "granularity": 3, "sneaky": "field"},
        headers={"Authorization": f"Bearer {token}", "X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()
