from offload_backend.dependencies import get_ai_inference_rate_limiter, get_provider
from offload_backend.providers.base import (
    ProviderDecisionResult,
    ProviderRequestError,
    ProviderTimeout,
)
from offload_backend.session_rate_limiter import InMemorySessionRateLimiter


class FakeDecisionProvider:
    provider_name = "fake"

    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        raise NotImplementedError

    async def compile_brain_dump(self, *, input_text, context_hints):
        raise NotImplementedError

    async def suggest_decisions(self, *, input_text, context_hints, clarifying_answers):
        _ = (input_text, context_hints, clarifying_answers)
        return ProviderDecisionResult(
            options=[
                {"title": "Option A", "description": "First good option", "is_recommended": True},
                {"title": "Option B", "description": "Second good option", "is_recommended": False},
            ],
            clarifying_questions=["What is your timeline?"],
            input_tokens=20,
            output_tokens=40,
        )


class TimeoutDecisionProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        raise NotImplementedError

    async def compile_brain_dump(self, *, input_text, context_hints):
        raise NotImplementedError

    async def suggest_decisions(self, *, input_text, context_hints, clarifying_answers):
        raise ProviderTimeout("provider timeout")


class FailureDecisionProvider:
    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        raise NotImplementedError

    async def compile_brain_dump(self, *, input_text, context_hints):
        raise NotImplementedError

    async def suggest_decisions(self, *, input_text, context_hints, clarifying_answers):
        raise ProviderRequestError("provider failure")


def test_decide_recommend_success(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={"input_text": "Should I use Postgres or SQLite?"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "fake"
    assert body["usage"]["input_tokens"] == 20
    assert len(body["options"]) == 2
    assert body["options"][0]["title"] == "Option A"
    assert body["options"][0]["is_recommended"] is True
    assert body["options"][1]["is_recommended"] is False
    assert body["clarifying_questions"] == ["What is your timeline?"]

    app.dependency_overrides.clear()


def test_decide_recommend_with_answers(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={
            "input_text": "Should I use Postgres or SQLite?",
            "clarifying_answers": [{"question": "What is your timeline?", "answer": "3 months"}],
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body["options"]) == 2

    app.dependency_overrides.clear()


def test_decide_recommend_rejects_missing_opt_in(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={"input_text": "Should I do A or B?"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "consent_required"

    app.dependency_overrides.clear()


def test_decide_recommend_rejects_missing_auth(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={"input_text": "Should I do A or B?"},
        headers={"X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 401

    app.dependency_overrides.clear()


def test_decide_recommend_rejects_oversized_input(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={"input_text": "a" * 2000},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_decide_recommend_rejects_too_many_answers(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={
            "input_text": "Should I do A or B?",
            "clarifying_answers": [
                {"question": f"Q{i}", "answer": f"A{i}"} for i in range(5)
            ],
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()


def test_decide_recommend_timeout_returns_504(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: TimeoutDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={"input_text": "Should I do A or B?"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 504
    assert response.json()["error"]["code"] == "provider_timeout"

    app.dependency_overrides.clear()


def test_decide_recommend_provider_failure_returns_502(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FailureDecisionProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/decide/recommend",
        json={"input_text": "Should I do A or B?"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 502

    app.dependency_overrides.clear()


def test_decide_rate_limit_enforced(client, app, create_session_token):
    limiter = InMemorySessionRateLimiter(limit_per_install=1, limit_per_ip=1000, window_seconds=60)
    app.dependency_overrides[get_provider] = lambda: FakeDecisionProvider()
    app.dependency_overrides[get_ai_inference_rate_limiter] = lambda: limiter
    token = create_session_token()

    headers = {
        "Authorization": f"Bearer {token}",
        "X-Offload-Cloud-Opt-In": "true",
    }
    payload = {"input_text": "Should I do A or B?"}

    first = client.post("/v1/ai/decide/recommend", json=payload, headers=headers)
    assert first.status_code == 200

    second = client.post("/v1/ai/decide/recommend", json=payload, headers=headers)
    assert second.status_code == 429

    app.dependency_overrides.clear()
