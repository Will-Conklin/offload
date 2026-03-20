from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from offload_backend.config import get_settings
from offload_backend.security import TokenManager


APPLE_SESSION_URL = '/v1/sessions/apple'
REFRESH_URL = '/v1/sessions/refresh'
MOCK_APPLE_USER_ID = '001234.abcdef1234567890.1234'
VERIFY_PATCH = 'offload_backend.routers.sessions_apple.verify_apple_identity_token'


def _make_token_manager() -> TokenManager:
    """Build a TokenManager from current test settings."""
    settings = get_settings()
    return TokenManager(
        secret=settings.session_secret,
        issuer=settings.session_token_issuer,
        audience=settings.session_token_audience,
        active_kid=settings.session_token_active_kid,
        signing_keys=settings.session_signing_keys,
    )


def _apple_session_payload(
    identity_token: str = 'fake-apple-jwt',
    install_id: str = 'install-12345',
) -> dict:
    return {
        'identity_token': identity_token,
        'install_id': install_id,
        'app_version': '1.0',
        'platform': 'ios',
    }


@pytest.fixture
def mock_verify():
    with patch(VERIFY_PATCH, new_callable=AsyncMock, return_value=MOCK_APPLE_USER_ID) as m:
        yield m


class TestAppleSession:
    def test_apple_session_returns_token(self, client: TestClient, mock_verify):
        resp = client.post(APPLE_SESSION_URL, json=_apple_session_payload())
        assert resp.status_code == 200
        data = resp.json()
        assert 'session_token' in data
        assert 'expires_at' in data

    def test_apple_session_token_contains_apple_user_id(self, client: TestClient, mock_verify):
        resp = client.post(APPLE_SESSION_URL, json=_apple_session_payload())
        assert resp.status_code == 200
        token = resp.json()['session_token']
        tm = _make_token_manager()
        claims = tm.decode(token)
        assert claims.apple_user_id == MOCK_APPLE_USER_ID

    def test_apple_session_rejects_invalid_token(self, client: TestClient):
        with patch(
            VERIFY_PATCH,
            new_callable=AsyncMock,
            side_effect=ValueError('bad token'),
        ):
            resp = client.post(APPLE_SESSION_URL, json=_apple_session_payload())
        assert resp.status_code == 401
        assert resp.json()['error']['code'] == 'invalid_apple_token'


class TestRefresh:
    def test_refresh_returns_new_token(self, client: TestClient, mock_verify):
        # Create an apple session first
        create_resp = client.post(APPLE_SESSION_URL, json=_apple_session_payload())
        assert create_resp.status_code == 200
        original_token = create_resp.json()['session_token']

        resp = client.post(
            REFRESH_URL,
            json={'session_token': original_token, 'install_id': 'install-12345'},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert 'session_token' in data
        assert 'expires_at' in data
        # Verify the refreshed token is decodable and carries the same apple_user_id
        tm = _make_token_manager()
        claims = tm.decode(data['session_token'])
        assert claims.install_id == 'install-12345'
        assert claims.apple_user_id == MOCK_APPLE_USER_ID

    def test_refresh_rejects_mismatched_install_id(self, client: TestClient, mock_verify):
        create_resp = client.post(APPLE_SESSION_URL, json=_apple_session_payload())
        assert create_resp.status_code == 200
        original_token = create_resp.json()['session_token']

        resp = client.post(
            REFRESH_URL,
            json={'session_token': original_token, 'install_id': 'wrong-install-id'},
        )
        assert resp.status_code == 401
        assert resp.json()['error']['code'] == 'install_id_mismatch'

    def test_refresh_rejects_invalid_signature(self, client: TestClient):
        resp = client.post(
            REFRESH_URL,
            json={'session_token': 'garbage.token', 'install_id': 'install-12345'},
        )
        assert resp.status_code == 401
        assert resp.json()['error']['code'] == 'invalid_token'
