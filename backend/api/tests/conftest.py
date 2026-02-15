import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient

from offload_backend.main import create_app


@pytest.fixture(autouse=True)
def test_env() -> Generator[None, None, None]:
    os.environ["OFFLOAD_SESSION_SECRET"] = "test-secret"
    os.environ["OFFLOAD_SESSION_TTL_SECONDS"] = "120"
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
