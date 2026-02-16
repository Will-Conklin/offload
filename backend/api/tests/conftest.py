import os
from collections.abc import Generator
from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient

from offload_backend.main import create_app
from offload_backend.security import SessionClaims, TokenManager


@pytest.fixture(autouse=True)
def test_env() -> Generator[None, None, None]:
    os.environ["OFFLOAD_SESSION_SECRET"] = "test-secret"
    os.environ["OFFLOAD_SESSION_TTL_SECONDS"] = "120"
    os.environ["OFFLOAD_SESSION_TOKEN_ISSUER"] = "offload-backend-test"
    os.environ["OFFLOAD_SESSION_TOKEN_AUDIENCE"] = "offload-ios-test"
    os.environ["OFFLOAD_SESSION_TOKEN_ACTIVE_KID"] = "test-kid"
    os.environ["OFFLOAD_OPENAI_MODEL"] = "gpt-4o-mini"
    os.environ["OFFLOAD_MAX_INPUT_CHARS"] = "1000"
    os.environ["OFFLOAD_DEFAULT_FEATURE_QUOTA"] = "10"
    os.environ["OFFLOAD_BUILD_VERSION"] = "test-build"
    yield


@pytest.fixture
def app():
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
