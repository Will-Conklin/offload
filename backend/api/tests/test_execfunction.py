from conftest import FailureAIProvider, FakeAIProvider, TimeoutAIProvider

from offload_backend.dependencies import get_ai_inference_rate_limiter, get_provider
from offload_backend.session_rate_limiter import InMemorySessionRateLimiter


def test_exec_function_prompt_success(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={"input_text": "I can't start this task, I keep putting it off"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "fake"
    assert body["usage"]["input_tokens"] == 25
    assert body["detected_challenge"] == "task_initiation"
    assert len(body["strategies"]) == 1
    assert body["strategies"][0]["strategy_id"] == "two_minute_rule"
    assert body["strategies"][0]["title"] == "The 2-Minute Rule"
    assert body["encouragement"] == "Starting is the bravest part."

    app.dependency_overrides.clear()


def test_exec_function_prompt_with_strategy_history(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={
            "input_text": "I can't start this task",
            "strategy_history": [
                {
                    "challenge_type": "task_initiation",
                    "strategy_id": "two_minute_rule",
                    "thumbs_up": True,
                    "led_to_completion": True,
                },
            ],
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body["strategies"]) == 1

    app.dependency_overrides.clear()


def test_exec_function_rejects_missing_opt_in(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={"input_text": "I'm stuck"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "consent_required"

    app.dependency_overrides.clear()


def test_exec_function_rejects_missing_auth(client, app):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={"input_text": "I'm stuck"},
        headers={"X-Offload-Cloud-Opt-In": "true"},
    )

    assert response.status_code == 401

    app.dependency_overrides.clear()


def test_exec_function_rejects_oversized_input(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={"input_text": "a" * 2000},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "request_too_large"

    app.dependency_overrides.clear()


def test_exec_function_rejects_too_many_history_entries(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={
            "input_text": "I'm stuck",
            "strategy_history": [
                {
                    "challenge_type": "task_initiation",
                    "strategy_id": f"strat_{i}",
                    "thumbs_up": True,
                    "led_to_completion": False,
                }
                for i in range(60)
            ],
        },
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()


def test_exec_function_timeout_returns_504(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: TimeoutAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={"input_text": "I'm stuck"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 504
    assert response.json()["error"]["code"] == "provider_timeout"

    app.dependency_overrides.clear()


def test_exec_function_provider_failure_returns_502(client, app, create_session_token):
    app.dependency_overrides[get_provider] = lambda: FailureAIProvider()
    token = create_session_token()

    response = client.post(
        "/v1/ai/executive-function/prompt",
        json={"input_text": "I'm stuck"},
        headers={
            "Authorization": f"Bearer {token}",
            "X-Offload-Cloud-Opt-In": "true",
        },
    )

    assert response.status_code == 502

    app.dependency_overrides.clear()


def test_exec_function_rate_limit_enforced(client, app, create_session_token):
    limiter = InMemorySessionRateLimiter(limit_per_install=1, limit_per_ip=1000, window_seconds=60)
    app.dependency_overrides[get_provider] = lambda: FakeAIProvider()
    app.dependency_overrides[get_ai_inference_rate_limiter] = lambda: limiter
    token = create_session_token()

    headers = {
        "Authorization": f"Bearer {token}",
        "X-Offload-Cloud-Opt-In": "true",
    }
    payload = {"input_text": "I'm stuck"}

    first = client.post("/v1/ai/executive-function/prompt", json=payload, headers=headers)
    assert first.status_code == 200

    second = client.post("/v1/ai/executive-function/prompt", json=payload, headers=headers)
    assert second.status_code == 429

    app.dependency_overrides.clear()
