import os
from collections.abc import Generator
from datetime import UTC, datetime, timedelta
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

import pytest
from fastapi.testclient import TestClient

from offload_backend.config import get_settings
from offload_backend.providers.base import (
    ProviderBrainDumpResult,
    ProviderBreakdownResult,
    ProviderDecisionResult,
    ProviderDraftResult,
    ProviderExecFunctionResult,
    ProviderRequestError,
    ProviderTimeout,
)
from offload_backend.security import SessionClaims, TokenManager


@pytest.fixture(autouse=True)
def test_env() -> Generator[None, None, None]:
    temp_dir = TemporaryDirectory()
    usage_db_path = Path(temp_dir.name) / "usage.sqlite3"
    get_settings.cache_clear()
    os.environ["OFFLOAD_SESSION_SECRET"] = "test-secret"
    os.environ["OFFLOAD_SESSION_TTL_SECONDS"] = "120"
    os.environ["OFFLOAD_SESSION_TOKEN_ISSUER"] = "offload-backend-test"
    os.environ["OFFLOAD_SESSION_TOKEN_AUDIENCE"] = "offload-ios-test"
    os.environ["OFFLOAD_SESSION_TOKEN_ACTIVE_KID"] = "test-kid"
    os.environ["OFFLOAD_OPENAI_MODEL"] = "gpt-4o-mini"
    os.environ["OFFLOAD_MAX_INPUT_CHARS"] = "1000"
    os.environ["OFFLOAD_DEFAULT_FEATURE_QUOTA"] = "10"
    os.environ["OFFLOAD_BUILD_VERSION"] = "test-build"
    os.environ["OFFLOAD_USAGE_DB_PATH"] = str(usage_db_path)
    try:
        yield
    finally:
        get_settings.cache_clear()
        temp_dir.cleanup()


@pytest.fixture
def app():
    from offload_backend.main import create_app

    return create_app()


@pytest.fixture
def client(app):
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def create_session_token(client: TestClient):
    def _create(install_id: str = "install-12345") -> str:
        response = client.post(
            "/v1/sessions/anonymous",
            json={"install_id": install_id, "app_version": "1.0", "platform": "ios"},
        )
        assert response.status_code == 200
        return str(response.json()["session_token"])

    return _create


@pytest.fixture
def create_expired_session_token():
    def _create(install_id: str = "install-12345", secret: str = "test-secret") -> str:
        manager = TokenManager(
            secret=secret,
            issuer=os.environ["OFFLOAD_SESSION_TOKEN_ISSUER"],
            audience=os.environ["OFFLOAD_SESSION_TOKEN_AUDIENCE"],
            active_kid=os.environ["OFFLOAD_SESSION_TOKEN_ACTIVE_KID"],
        )
        expired_claims = SessionClaims(
            install_id=install_id,
            expires_at=datetime.now(UTC) - timedelta(seconds=1),
        )
        return manager.encode(expired_claims)

    return _create


@pytest.fixture
def post_usage_reconcile(client: TestClient):
    def _post(
        *,
        authorization: str | None = None,
        install_id: str = "install-12345",
        feature: str = "breakdown",
        local_count: int = 1,
    ):
        headers: dict[str, str] = {}
        if authorization is not None:
            headers["Authorization"] = authorization
        return client.post(
            "/v1/usage/reconcile",
            json={"install_id": install_id, "feature": feature, "local_count": local_count},
            headers=headers or None,
        )

    return _post


@pytest.fixture
def post_breakdown_generate(client: TestClient):
    def _post(
        *,
        authorization: str | None = None,
        opt_in: bool = True,
        payload: dict[str, Any] | None = None,
    ):
        headers: dict[str, str] = {}
        if authorization is not None:
            headers["Authorization"] = authorization
        if opt_in:
            headers["X-Offload-Cloud-Opt-In"] = "true"
        return client.post(
            "/v1/ai/breakdown/generate",
            json=payload or {"input_text": "Clean the kitchen", "granularity": 3},
            headers=headers or None,
        )

    return _post


@pytest.fixture
def make_breakdown_payload():
    def _make(**overrides: Any) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "input_text": "Clean the kitchen",
            "granularity": 3,
            "context_hints": [],
            "template_ids": [],
        }
        payload.update(overrides)
        return payload

    return _make


# ---------------------------------------------------------------------------
# Shared fake AI providers for router tests
# ---------------------------------------------------------------------------


class FakeAIProvider:
    """Fake provider returning canned responses for all AI endpoints."""

    provider_name = "fake"

    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        _ = (input_text, granularity, context_hints, template_ids)
        return ProviderBreakdownResult(
            steps=[{"title": "Step 1", "substeps": [{"title": "Substep 1.1", "substeps": []}]}],
            input_tokens=10,
            output_tokens=20,
        )

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

    async def prompt_executive_function(self, *, input_text, context_hints, strategy_history):
        _ = (input_text, context_hints, strategy_history)
        return ProviderExecFunctionResult(
            detected_challenge="task_initiation",
            strategies=[
                {
                    "strategy_id": "two_minute_rule",
                    "challenge_type": "task_initiation",
                    "title": "The 2-Minute Rule",
                    "description": "Commit to just 2 minutes of work.",
                    "action_prompt": "Set a timer for 2 minutes and begin.",
                },
            ],
            encouragement="Starting is the bravest part.",
            input_tokens=25,
            output_tokens=45,
        )

    async def draft_communication(self, *, input_text, channel, contact_name, context_hints):
        _ = (input_text, channel, contact_name, context_hints)
        return ProviderDraftResult(
            draft_text="Hi! I wanted to reach out about this.",
            tone="friendly",
            input_tokens=30,
            output_tokens=50,
        )


class TimeoutAIProvider:
    """Provider that raises ProviderTimeout on every method."""

    async def generate_breakdown(self, **_):
        raise ProviderTimeout("provider timeout")

    async def compile_brain_dump(self, **_):
        raise ProviderTimeout("provider timeout")

    async def suggest_decisions(self, **_):
        raise ProviderTimeout("provider timeout")

    async def prompt_executive_function(self, **_):
        raise ProviderTimeout("provider timeout")

    async def draft_communication(self, **_):
        raise ProviderTimeout("provider timeout")


class FailureAIProvider:
    """Provider that raises ProviderRequestError on every method."""

    async def generate_breakdown(self, **_):
        raise ProviderRequestError("provider failure")

    async def compile_brain_dump(self, **_):
        raise ProviderRequestError("provider failure")

    async def suggest_decisions(self, **_):
        raise ProviderRequestError("provider failure")

    async def prompt_executive_function(self, **_):
        raise ProviderRequestError("provider failure")

    async def draft_communication(self, **_):
        raise ProviderRequestError("provider failure")
