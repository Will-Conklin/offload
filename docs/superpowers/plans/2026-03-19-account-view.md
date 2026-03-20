# Account View Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build out the AccountView with Sign in with Apple auth, usage/quota display, cloud AI consent, preferences, and about — replacing the current placeholder and merging SettingsView.

**Architecture:** Backend-first approach. Extend session token system with optional `apple_user_id` claim and refresh endpoint, then build iOS auth manager and account UI. Two independent subsystems (backend sessions, iOS UI) connected by API contracts.

**Tech Stack:** Python/FastAPI (backend), PyJWT+cryptography (Apple JWKS), Swift/SwiftUI (iOS), AuthenticationServices framework, Keychain Services

**Spec:** `docs/superpowers/specs/2026-03-19-account-view-design.md`

---

## File Structure

### Backend (new/modified)

| File | Responsibility |
|------|---------------|
| `backend/api/src/offload_backend/security.py` | Add `apple_user_id` to SessionClaims, `allow_expired` to decode() |
| `backend/api/src/offload_backend/config.py` | Add `OFFLOAD_APPLE_BUNDLE_ID` setting |
| `backend/api/src/offload_backend/schemas.py` | Rename `AnonymousSessionResponse` → `SessionResponse`, add Apple/refresh request schemas |
| `backend/api/src/offload_backend/routers/sessions.py` | Update to use renamed `SessionResponse` |
| `backend/api/src/offload_backend/routers/sessions_apple.py` | New: Apple auth + refresh endpoints |
| `backend/api/src/offload_backend/main.py` | Register new router |
| `backend/api/pyproject.toml` | Add PyJWT + cryptography |
| `backend/api/tests/test_sessions_apple.py` | New: tests for apple auth + refresh |
| `backend/api/tests/test_session_token_v2.py` | Add tests for apple_user_id claim + allow_expired |
| `backend/api/tests/conftest.py` | Add `token_manager`, `expired_token_manager`, Apple RSA fixtures |

### iOS (new/modified)

| File | Responsibility |
|------|---------------|
| `ios/Offload/Data/Networking/AIBackendContracts.swift` | Add Apple/refresh contracts, rename response |
| `ios/Offload/Data/Networking/AIBackendClient.swift` | Add protocol method, auth-aware refresh |
| `ios/Offload/Data/Networking/KeychainSessionTokenStore.swift` | New: Keychain-backed token persistence |
| `ios/Offload/Data/Services/AuthManager.swift` | New: Sign in with Apple lifecycle |
| `ios/Offload/Features/Settings/TagManagementView.swift` | New: extracted from SettingsView |
| `ios/Offload/Features/Settings/AccountView.swift` | Rewrite: full account screen |
| `ios/Offload/Features/Settings/SettingsView.swift` | Delete |
| `ios/Offload/App/AppRootView.swift` | Inject AuthManager |
| `ios/Offload/App/MainTabView.swift` | Remove SettingsView references |

---

## Task 1: Extend SessionClaims with optional apple_user_id

**Files:**
- Modify: `backend/api/src/offload_backend/security.py:29-33` (SessionClaims), `:60-67` (issue_session), `:69-88` (encode), `:90-141` (decode)
- Test: `backend/api/tests/test_session_token_v2.py`

- [ ] **Step 1: Write failing test — apple_user_id in SessionClaims**

Add to `backend/api/tests/test_session_token_v2.py`:

```python
def test_session_claims_supports_optional_apple_user_id(token_manager: TokenManager) -> None:
    """SessionClaims accepts apple_user_id; anonymous sessions default to None."""
    claims = token_manager.issue_session('test-install', ttl_seconds=60)
    assert claims.apple_user_id is None

    claims_with_apple = token_manager.issue_session(
        'test-install', ttl_seconds=60, apple_user_id='apple.user.001'
    )
    assert claims_with_apple.apple_user_id == 'apple.user.001'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend/api && python -m pytest tests/test_session_token_v2.py::test_session_claims_supports_optional_apple_user_id -v`
Expected: FAIL — `issue_session()` does not accept `apple_user_id`

- [ ] **Step 3: Add apple_user_id to SessionClaims and issue_session**

In `security.py`, update `SessionClaims` (line 29):

```python
class SessionClaims(BaseModel):
    model_config = ConfigDict(frozen=True)
    install_id: str
    expires_at: datetime
    apple_user_id: str | None = None
```

Update `issue_session()` (line 60):

```python
def issue_session(
    self, install_id: str, ttl_seconds: int, *, apple_user_id: str | None = None
) -> SessionClaims:
    exp = self._clock() + timedelta(seconds=ttl_seconds)
    return SessionClaims(
        install_id=install_id, expires_at=exp, apple_user_id=apple_user_id
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend/api && python -m pytest tests/test_session_token_v2.py::test_session_claims_supports_optional_apple_user_id -v`
Expected: PASS

- [ ] **Step 5: Write failing test — apple_user_id round-trips through encode/decode**

Add to `backend/api/tests/test_session_token_v2.py`:

```python
def test_apple_user_id_round_trips_through_token(token_manager: TokenManager) -> None:
    """apple_user_id survives encode → decode when present."""
    claims = token_manager.issue_session(
        'test-install', ttl_seconds=60, apple_user_id='apple.user.002'
    )
    token = token_manager.encode(claims)
    decoded = token_manager.decode(token)
    assert decoded.apple_user_id == 'apple.user.002'


def test_anonymous_token_has_no_apple_user_id(token_manager: TokenManager) -> None:
    """Anonymous sessions decode with apple_user_id=None."""
    claims = token_manager.issue_session('test-install', ttl_seconds=60)
    token = token_manager.encode(claims)
    decoded = token_manager.decode(token)
    assert decoded.apple_user_id is None
```

- [ ] **Step 6: Run tests to verify they fail**

Run: `cd backend/api && python -m pytest tests/test_session_token_v2.py::test_apple_user_id_round_trips_through_token tests/test_session_token_v2.py::test_anonymous_token_has_no_apple_user_id -v`
Expected: FAIL — encode/decode don't handle apple_user_id

- [ ] **Step 7: Update encode() and _parse_v2_claims() for apple_user_id**

In `encode()`, after the payload dict is built (around line 78), add `apple_user_id` when present:

```python
# Inside encode(), after building the payload dict:
if claims.apple_user_id is not None:
    payload['apple_user_id'] = claims.apple_user_id
```

In `_parse_v2_claims()`, extract apple_user_id with `.get()`:

```python
# Inside _parse_v2_claims(), when building SessionClaims:
apple_user_id=payload.get('apple_user_id')
```

Do NOT add `apple_user_id` to `REQUIRED_V2_CLAIMS`.

- [ ] **Step 8: Run tests to verify they pass**

Run: `cd backend/api && python -m pytest tests/test_session_token_v2.py -v`
Expected: ALL PASS (including existing tests — backwards compatible)

- [ ] **Step 9: Write failing test — allow_expired decode**

Add to `backend/api/tests/test_session_token_v2.py`:

```python
def test_decode_allow_expired_skips_expiry_check(expired_token_manager: TokenManager) -> None:
    """decode(allow_expired=True) accepts expired tokens with valid signatures."""
    claims = expired_token_manager.issue_session('test-install', ttl_seconds=1)
    token = expired_token_manager.encode(claims)

    # Normal decode should reject
    with pytest.raises(ExpiredTokenError):
        expired_token_manager.decode(token)

    # allow_expired should accept
    decoded = expired_token_manager.decode(token, allow_expired=True)
    assert decoded.install_id == 'test-install'
```

Note: `expired_token_manager` is a fixture that uses a `now_provider` set 2 hours in the future. Add to `conftest.py`:

```python
@pytest.fixture
def expired_token_manager(test_env: None) -> TokenManager:
    """TokenManager with now_provider set 2 hours in the future."""
    future = datetime.now(timezone.utc) + timedelta(hours=2)
    settings = get_app_settings()
    return TokenManager(
        secret=settings.session_secret,
        issuer=settings.session_token_issuer,
        audience=settings.session_token_audience,
        active_kid=settings.session_token_active_kid,
        signing_keys=settings.session_signing_keys,
        now_provider=lambda: future,
    )
```

Also needs the regular `token_manager` fixture if not already present:

```python
@pytest.fixture
def token_manager(test_env: None) -> TokenManager:
    """Standard TokenManager from test settings."""
    settings = get_app_settings()
    return TokenManager(
        secret=settings.session_secret,
        issuer=settings.session_token_issuer,
        audience=settings.session_token_audience,
        active_kid=settings.session_token_active_kid,
        signing_keys=settings.session_signing_keys,
    )
```

- [ ] **Step 10: Run test to verify it fails**

Run: `cd backend/api && python -m pytest tests/test_session_token_v2.py::test_decode_allow_expired_skips_expiry_check -v`
Expected: FAIL — `decode()` does not accept `allow_expired` parameter

- [ ] **Step 11: Add allow_expired parameter to decode()**

In `decode()` (line 90), add the parameter and skip expiry check when True:

```python
def decode(self, token: str, *, allow_expired: bool = False) -> SessionClaims:
```

In the expiry check section (around line 130), wrap with:

```python
if not allow_expired:
    # existing expiry validation logic
    if now >= exp:
        raise ExpiredTokenError(...)
```

- [ ] **Step 12: Run all security tests to verify everything passes**

Run: `cd backend/api && python -m pytest tests/test_session_token_v2.py tests/test_sessions_auth.py -v`
Expected: ALL PASS

- [ ] **Step 13: Commit**

```bash
git add backend/api/src/offload_backend/security.py backend/api/tests/test_session_token_v2.py
git commit -m "feat(auth): extend SessionClaims with optional apple_user_id and allow_expired decode"
```

---

## Task 2: Rename AnonymousSessionResponse → SessionResponse and add config

**Files:**
- Modify: `backend/api/src/offload_backend/schemas.py:22-24`
- Modify: `backend/api/src/offload_backend/routers/sessions.py:19`
- Modify: `backend/api/src/offload_backend/config.py`
- Test: `backend/api/tests/test_sessions_auth.py`, `backend/api/tests/test_config.py`

- [ ] **Step 1: Rename AnonymousSessionResponse → SessionResponse in schemas.py**

In `schemas.py` (line 22), rename the class:

```python
class SessionResponse(BaseModel):
    session_token: str
    expires_at: datetime
```

- [ ] **Step 2: Update sessions.py to use SessionResponse**

In `routers/sessions.py` (line 19), update the import and response_model:

```python
# Update import
from offload_backend.schemas import AnonymousSessionRequest, SessionResponse

# Update decorator
@router.post('/sessions/anonymous', response_model=SessionResponse)
```

Update the return statement to use `SessionResponse` instead of `AnonymousSessionResponse`.

- [ ] **Step 3: Add Apple request schemas to schemas.py**

Add to `schemas.py`:

```python
class AppleSessionRequest(BaseModel):
    identity_token: str = Field(..., min_length=1)
    install_id: str = Field(..., min_length=8, max_length=128)
    app_version: str = Field(..., min_length=1, max_length=32)
    platform: str = Field(..., min_length=1, max_length=32)


class SessionRefreshRequest(BaseModel):
    session_token: str = Field(..., min_length=1)
    install_id: str = Field(..., min_length=8, max_length=128)
```

- [ ] **Step 4: Add OFFLOAD_APPLE_BUNDLE_ID to config.py**

In `config.py`, add to the `Settings` class (after line 32):

```python
apple_bundle_id: str = 'wc.Offload'
```

- [ ] **Step 5: Run existing tests to verify rename is backwards compatible**

Run: `cd backend/api && python -m pytest tests/ -v`
Expected: ALL PASS — rename doesn't break behavior

- [ ] **Step 6: Commit**

```bash
git add backend/api/src/offload_backend/schemas.py backend/api/src/offload_backend/routers/sessions.py backend/api/src/offload_backend/config.py
git commit -m "refactor(auth): rename AnonymousSessionResponse to SessionResponse, add Apple schemas and config"
```

---

## Task 3: Add PyJWT dependency and Apple JWKS verification

**Files:**
- Modify: `backend/api/pyproject.toml`
- Create: `backend/api/src/offload_backend/apple_jwt.py`
- Test: `backend/api/tests/test_apple_jwt.py`

- [ ] **Step 1: Add PyJWT + cryptography to pyproject.toml**

In `pyproject.toml`, add to dependencies:

```toml
"PyJWT[crypto]>=2.9.0",
```

Also add `pytest-asyncio` to dev dependencies (needed for `@pytest.mark.asyncio` in Apple JWT tests):

```toml
"pytest-asyncio>=0.24.0,<1.0.0",
```

- [ ] **Step 2: Install dependencies**

Run: `cd backend/api && uv sync`

- [ ] **Step 3: Write failing test — Apple identity token verification**

Create `backend/api/tests/test_apple_jwt.py`:

```python
"""Tests for Apple identity token verification."""

import json
import time
from unittest.mock import AsyncMock, patch

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

from offload_backend.apple_jwt import verify_apple_identity_token


@pytest.fixture
def apple_rsa_key():
    """Generate an RSA key pair for testing."""
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    return private_key


@pytest.fixture
def apple_jwks(apple_rsa_key):
    """Create a JWKS response matching the test key."""
    public_key = apple_rsa_key.public_key()
    public_numbers = public_key.public_numbers()

    import base64

    def _int_to_base64url(n: int, length: int) -> str:
        return base64.urlsafe_b64encode(n.to_bytes(length, 'big')).rstrip(b'=').decode()

    return {
        'keys': [
            {
                'kty': 'RSA',
                'kid': 'test-kid-001',
                'use': 'sig',
                'alg': 'RS256',
                'n': _int_to_base64url(public_numbers.n, 256),
                'e': _int_to_base64url(public_numbers.e, 3),
            }
        ]
    }


@pytest.fixture
def make_apple_token(apple_rsa_key):
    """Factory for creating signed Apple identity tokens."""

    def _make(
        sub: str = 'apple.user.001',
        iss: str = 'https://appleid.apple.com',
        aud: str = 'wc.Offload',
        exp: int | None = None,
        kid: str = 'test-kid-001',
    ) -> str:
        payload = {
            'sub': sub,
            'iss': iss,
            'aud': aud,
            'exp': exp or int(time.time()) + 300,
            'iat': int(time.time()),
        }
        return jwt.encode(
            payload,
            apple_rsa_key,
            algorithm='RS256',
            headers={'kid': kid},
        )

    return _make


@pytest.mark.asyncio
async def test_verify_valid_apple_token(make_apple_token, apple_jwks):
    """Valid Apple identity token returns the sub claim."""
    token = make_apple_token(sub='apple.user.123')

    with patch(
        'offload_backend.apple_jwt._fetch_apple_jwks', new_callable=AsyncMock, return_value=apple_jwks
    ):
        result = await verify_apple_identity_token(token, expected_audience='wc.Offload')

    assert result == 'apple.user.123'


@pytest.mark.asyncio
async def test_verify_rejects_wrong_audience(make_apple_token, apple_jwks):
    """Token with wrong audience is rejected."""
    token = make_apple_token(aud='wrong.bundle.id')

    with patch(
        'offload_backend.apple_jwt._fetch_apple_jwks', new_callable=AsyncMock, return_value=apple_jwks
    ):
        with pytest.raises(ValueError, match='audience'):
            await verify_apple_identity_token(token, expected_audience='wc.Offload')


@pytest.mark.asyncio
async def test_verify_rejects_wrong_issuer(make_apple_token, apple_jwks):
    """Token with wrong issuer is rejected."""
    token = make_apple_token(iss='https://evil.com')

    with patch(
        'offload_backend.apple_jwt._fetch_apple_jwks', new_callable=AsyncMock, return_value=apple_jwks
    ):
        with pytest.raises(ValueError, match='issuer'):
            await verify_apple_identity_token(token, expected_audience='wc.Offload')


@pytest.mark.asyncio
async def test_verify_rejects_expired_token(make_apple_token, apple_jwks):
    """Expired Apple token is rejected."""
    token = make_apple_token(exp=int(time.time()) - 60)

    with patch(
        'offload_backend.apple_jwt._fetch_apple_jwks', new_callable=AsyncMock, return_value=apple_jwks
    ):
        with pytest.raises(ValueError, match='expired'):
            await verify_apple_identity_token(token, expected_audience='wc.Offload')
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cd backend/api && python -m pytest tests/test_apple_jwt.py -v`
Expected: FAIL — module does not exist

- [ ] **Step 5: Implement apple_jwt.py**

Create `backend/api/src/offload_backend/apple_jwt.py`:

```python
"""Apple identity token (JWT) verification using Apple's JWKS."""

import time

import httpx
import jwt

APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys'
APPLE_ISSUER = 'https://appleid.apple.com'

_jwks_cache: dict | None = None
_jwks_cache_time: float = 0.0
_JWKS_CACHE_TTL = 86400  # 24 hours


async def _fetch_apple_jwks() -> dict:
    """Fetch Apple's JWKS, with 24-hour in-memory cache and key-miss refresh."""
    global _jwks_cache, _jwks_cache_time
    now = time.monotonic()
    if _jwks_cache is not None and (now - _jwks_cache_time) < _JWKS_CACHE_TTL:
        return _jwks_cache
    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_JWKS_URL, timeout=10)
        resp.raise_for_status()
        _jwks_cache = resp.json()
        _jwks_cache_time = now
        return _jwks_cache


def _invalidate_jwks_cache() -> None:
    """Force next fetch to refresh the cache (used on key-miss)."""
    global _jwks_cache, _jwks_cache_time
    _jwks_cache = None
    _jwks_cache_time = 0.0


async def verify_apple_identity_token(token: str, *, expected_audience: str) -> str:
    """Verify an Apple identity token and return the Apple user ID (sub claim).

    Args:
        token: The identity token JWT from ASAuthorizationAppleIDCredential.
        expected_audience: The app's bundle ID (e.g., 'wc.Offload').

    Returns:
        The Apple user ID (sub claim) from the verified token.

    Raises:
        ValueError: If the token is invalid, expired, or has wrong issuer/audience.
    """
    jwks_data = await _fetch_apple_jwks()
    jwk_client = jwt.PyJWKSet.from_dict(jwks_data)

    try:
        # Get the signing key from the token header
        unverified_header = jwt.get_unverified_header(token)
        kid = unverified_header.get('kid')
        if not kid:
            msg = 'Token missing kid header'
            raise ValueError(msg)

        # Find matching key
        signing_key = None
        for key in jwk_client.keys:
            if key.key_id == kid:
                signing_key = key
                break

        if signing_key is None:
            # Key-miss: refresh cache and retry once
            _invalidate_jwks_cache()
            jwks_data = await _fetch_apple_jwks()
            jwk_client = jwt.PyJWKSet.from_dict(jwks_data)
            for key in jwk_client.keys:
                if key.key_id == kid:
                    signing_key = key
                    break

        if signing_key is None:
            msg = f'No matching key found for kid={kid}'
            raise ValueError(msg)

        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=['RS256'],
            audience=expected_audience,
            issuer=APPLE_ISSUER,
        )

        sub = payload.get('sub')
        if not sub:
            msg = 'Token missing sub claim'
            raise ValueError(msg)

        return sub

    except jwt.ExpiredSignatureError:
        msg = 'Apple identity token expired'
        raise ValueError(msg) from None
    except jwt.InvalidAudienceError:
        msg = f'Invalid audience: expected {expected_audience}'
        raise ValueError(msg) from None
    except jwt.InvalidIssuerError:
        msg = f'Invalid issuer: expected {APPLE_ISSUER}'
        raise ValueError(msg) from None
    except jwt.PyJWTError as e:
        msg = f'Invalid Apple identity token: {e}'
        raise ValueError(msg) from None
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd backend/api && python -m pytest tests/test_apple_jwt.py -v`
Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
git add backend/api/pyproject.toml backend/api/src/offload_backend/apple_jwt.py backend/api/tests/test_apple_jwt.py
git commit -m "feat(auth): add Apple identity token JWKS verification module"
```

---

## Task 4: Apple session and refresh endpoints

**Files:**
- Create: `backend/api/src/offload_backend/routers/sessions_apple.py`
- Modify: `backend/api/src/offload_backend/main.py:84-89`
- Create: `backend/api/tests/test_sessions_apple.py`

- [ ] **Step 1: Write failing tests for Apple session endpoint**

Create `backend/api/tests/test_sessions_apple.py`:

```python
"""Tests for Apple session and refresh endpoints."""

import time
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi.testclient import TestClient

from offload_backend.main import create_app


@pytest.fixture
def apple_rsa_key():
    """Generate an RSA key pair for testing."""
    return rsa.generate_private_key(public_exponent=65537, key_size=2048)


@pytest.fixture
def apple_jwks(apple_rsa_key):
    """Create a JWKS response matching the test key."""
    import base64

    public_key = apple_rsa_key.public_key()
    public_numbers = public_key.public_numbers()

    def _int_to_base64url(n: int, length: int) -> str:
        return base64.urlsafe_b64encode(n.to_bytes(length, 'big')).rstrip(b'=').decode()

    return {
        'keys': [
            {
                'kty': 'RSA',
                'kid': 'test-kid-001',
                'use': 'sig',
                'alg': 'RS256',
                'n': _int_to_base64url(public_numbers.n, 256),
                'e': _int_to_base64url(public_numbers.e, 3),
            }
        ]
    }


@pytest.fixture
def make_apple_token(apple_rsa_key):
    """Factory for creating signed Apple identity tokens."""

    def _make(sub: str = 'apple.user.001', aud: str = 'wc.Offload') -> str:
        payload = {
            'sub': sub,
            'iss': 'https://appleid.apple.com',
            'aud': aud,
            'exp': int(time.time()) + 300,
            'iat': int(time.time()),
        }
        return jwt.encode(payload, apple_rsa_key, algorithm='RS256', headers={'kid': 'test-kid-001'})

    return _make


def test_apple_session_returns_token(
    test_env: None, client: TestClient, make_apple_token, apple_jwks
) -> None:
    """POST /v1/sessions/apple returns session_token and expires_at."""
    token = make_apple_token(sub='apple.user.001')

    with patch('offload_backend.routers.sessions_apple.verify_apple_identity_token', new_callable=AsyncMock, return_value='apple.user.001'):
        resp = client.post(
            '/v1/sessions/apple',
            json={
                'identity_token': token,
                'install_id': 'test-install-id-12345',
                'app_version': '1.0.0',
                'platform': 'ios',
            },
        )

    assert resp.status_code == 200
    data = resp.json()
    assert 'session_token' in data
    assert 'expires_at' in data


def test_apple_session_token_contains_apple_user_id(
    test_env: None, client: TestClient, make_apple_token, apple_jwks
) -> None:
    """Apple session token includes apple_user_id claim."""
    token = make_apple_token(sub='apple.user.002')

    with patch('offload_backend.routers.sessions_apple.verify_apple_identity_token', new_callable=AsyncMock, return_value='apple.user.002'):
        resp = client.post(
            '/v1/sessions/apple',
            json={
                'identity_token': token,
                'install_id': 'test-install-id-12345',
                'app_version': '1.0.0',
                'platform': 'ios',
            },
        )

    session_token = resp.json()['session_token']
    # Decode with the test token manager to verify claims
    from offload_backend.dependencies import get_token_manager
    from offload_backend.config import get_app_settings

    tm = get_token_manager(get_app_settings())
    claims = tm.decode(session_token)
    assert claims.apple_user_id == 'apple.user.002'


def test_apple_session_rejects_invalid_token(test_env: None, client: TestClient) -> None:
    """POST /v1/sessions/apple rejects invalid identity tokens."""
    with patch(
        'offload_backend.routers.sessions_apple.verify_apple_identity_token',
        new_callable=AsyncMock,
        side_effect=ValueError('Invalid Apple identity token'),
    ):
        resp = client.post(
            '/v1/sessions/apple',
            json={
                'identity_token': 'garbage.token.here',
                'install_id': 'test-install-id-12345',
                'app_version': '1.0.0',
                'platform': 'ios',
            },
        )

    assert resp.status_code == 401


def test_refresh_returns_new_token(test_env: None, client: TestClient, make_apple_token) -> None:
    """POST /v1/sessions/refresh returns a fresh token for a valid expired token."""
    # First create an apple session
    with patch('offload_backend.routers.sessions_apple.verify_apple_identity_token', new_callable=AsyncMock, return_value='apple.user.001'):
        resp = client.post(
            '/v1/sessions/apple',
            json={
                'identity_token': 'valid.apple.token',
                'install_id': 'test-install-id-12345',
                'app_version': '1.0.0',
                'platform': 'ios',
            },
        )

    old_token = resp.json()['session_token']

    resp2 = client.post(
        '/v1/sessions/refresh',
        json={
            'session_token': old_token,
            'install_id': 'test-install-id-12345',
        },
    )

    assert resp2.status_code == 200
    new_token = resp2.json()['session_token']
    assert new_token != old_token


def test_refresh_rejects_mismatched_install_id(test_env: None, client: TestClient) -> None:
    """Refresh rejects when install_id doesn't match token."""
    with patch('offload_backend.routers.sessions_apple.verify_apple_identity_token', new_callable=AsyncMock, return_value='apple.user.001'):
        resp = client.post(
            '/v1/sessions/apple',
            json={
                'identity_token': 'valid.apple.token',
                'install_id': 'test-install-id-12345',
                'app_version': '1.0.0',
                'platform': 'ios',
            },
        )

    old_token = resp.json()['session_token']

    resp2 = client.post(
        '/v1/sessions/refresh',
        json={
            'session_token': old_token,
            'install_id': 'wrong-install-id-99999',
        },
    )

    assert resp2.status_code == 401


def test_refresh_rejects_invalid_signature(test_env: None, client: TestClient) -> None:
    """Refresh rejects tokens with invalid signatures."""
    resp = client.post(
        '/v1/sessions/refresh',
        json={
            'session_token': 'v2:garbage:fakesig',
            'install_id': 'test-install-id-12345',
        },
    )

    assert resp.status_code == 401
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend/api && python -m pytest tests/test_sessions_apple.py -v`
Expected: FAIL — module does not exist

- [ ] **Step 3: Implement sessions_apple.py router**

Create `backend/api/src/offload_backend/routers/sessions_apple.py`:

```python
"""Apple Sign-In session and token refresh endpoints."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Request

from offload_backend.apple_jwt import verify_apple_identity_token
from offload_backend.config import Settings, get_app_settings
from offload_backend.dependencies import (
    enforce_session_issuance_rate_limit,
    get_session_rate_limiter,
    get_token_manager,
)
from offload_backend.errors import APIException
from offload_backend.schemas import AppleSessionRequest, SessionRefreshRequest, SessionResponse
from offload_backend.security import InvalidTokenError, TokenManager
from offload_backend.session_rate_limiter import SessionRateLimiter

router = APIRouter(tags=['sessions'])

_MAX_REFRESH_AGE_SECONDS = 30 * 24 * 3600  # 30 days


@router.post('/sessions/apple', response_model=SessionResponse)
async def create_apple_session(
    body: AppleSessionRequest,
    request: Request,
    settings: Settings = Depends(get_app_settings),
    token_manager: TokenManager = Depends(get_token_manager),
    limiter: SessionRateLimiter = Depends(get_session_rate_limiter),
) -> SessionResponse:
    """Exchange an Apple identity token for an authenticated session."""
    enforce_session_issuance_rate_limit(
        install_id=body.install_id,
        request=request,
        limiter=limiter,
    )

    try:
        apple_user_id = await verify_apple_identity_token(
            body.identity_token, expected_audience=settings.apple_bundle_id
        )
    except ValueError as e:
        raise APIException(status_code=401, code='invalid_apple_token', message=str(e)) from e

    claims = token_manager.issue_session(
        body.install_id,
        ttl_seconds=settings.session_ttl_seconds,
        apple_user_id=apple_user_id,
    )
    token = token_manager.encode(claims)
    return SessionResponse(session_token=token, expires_at=claims.expires_at)


@router.post('/sessions/refresh', response_model=SessionResponse)
async def refresh_session(
    body: SessionRefreshRequest,
    request: Request,
    settings: Settings = Depends(get_app_settings),
    token_manager: TokenManager = Depends(get_token_manager),
    limiter: SessionRateLimiter = Depends(get_session_rate_limiter),
) -> SessionResponse:
    """Refresh an expired session token (must have valid signature)."""
    enforce_session_issuance_rate_limit(
        install_id=body.install_id,
        request=request,
        limiter=limiter,
    )

    try:
        old_claims = token_manager.decode(body.session_token, allow_expired=True)
    except (InvalidTokenError, TokenError) as e:
        raise APIException(status_code=401, code='invalid_token', message='Invalid session token') from e

    # Validate install_id matches
    if old_claims.install_id != body.install_id:
        raise APIException(status_code=401, code='install_id_mismatch', message='install_id does not match token')

    # Reject tokens older than 30 days (use expires_at + ttl as proxy for issued_at)
    now = datetime.now(timezone.utc)
    token_age = (now - old_claims.expires_at).total_seconds() + settings.session_ttl_seconds
    if token_age > _MAX_REFRESH_AGE_SECONDS:
        raise APIException(status_code=401, code='token_too_old', message='Session too old, sign in again')

    # Issue fresh token with same claims
    new_claims = token_manager.issue_session(
        old_claims.install_id,
        ttl_seconds=settings.session_ttl_seconds,
        apple_user_id=old_claims.apple_user_id,
    )
    token = token_manager.encode(new_claims)
    return SessionResponse(session_token=token, expires_at=new_claims.expires_at)
```

- [ ] **Step 4: Register router in main.py**

In `main.py`, add after the existing session router import (around line 84):

```python
from offload_backend.routers.sessions_apple import router as sessions_apple_router
# ...
app.include_router(sessions_apple_router, prefix='/v1')
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd backend/api && python -m pytest tests/test_sessions_apple.py -v`
Expected: ALL PASS

- [ ] **Step 6: Run full backend test suite**

Run: `cd backend/api && python -m pytest tests/ -v`
Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
git add backend/api/src/offload_backend/routers/sessions_apple.py backend/api/src/offload_backend/main.py backend/api/tests/test_sessions_apple.py
git commit -m "feat(auth): add Apple session and token refresh endpoints"
```

---

## Task 5: iOS contract updates (rename + new types)

**Files:**
- Modify: `ios/Offload/Data/Networking/AIBackendContracts.swift:20-28`
- Modify: `ios/Offload/Data/Networking/AIBackendClient.swift` (references to AnonymousSessionResponse)

- [ ] **Step 1: Rename AnonymousSessionResponse → SessionResponse in AIBackendContracts.swift**

In `AIBackendContracts.swift` (line 20), rename:

```swift
struct SessionResponse: Codable, Equatable {
    let sessionToken: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case expiresAt = "expires_at"
    }
}
```

Note: preserve `Equatable` conformance from original `AnonymousSessionResponse`.

- [ ] **Step 2: Add new contract types to AIBackendContracts.swift**

Add after `SessionResponse`:

```swift
// MARK: - Apple Session

struct AppleSessionRequest: Codable {
    let identityToken: String
    let installId: String
    let appVersion: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case installId = "install_id"
        case appVersion = "app_version"
        case platform
    }
}

struct SessionRefreshRequest: Codable {
    let sessionToken: String
    let installId: String

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case installId = "install_id"
    }
}
```

- [ ] **Step 3: Update AIBackendClient.swift references**

Find all references to `AnonymousSessionResponse` in `AIBackendClient.swift` and replace with `SessionResponse`. These are in `createAnonymousSession()` around line 167.

- [ ] **Step 4: Add createAppleSession to AIBackendClient protocol**

In `AIBackendClient.swift` (line 131), add to the protocol. Follow the existing pattern where each method takes a request and returns a response:

```swift
protocol AIBackendClient {
    func createAnonymousSession(request: AnonymousSessionRequest) async throws -> SessionResponse
    func createAppleSession(request: AppleSessionRequest) async throws -> SessionResponse
    func refreshSessionToken(request: SessionRefreshRequest) async throws -> SessionResponse
    func generateBreakdown(request: BreakdownGenerateRequest) async throws -> BreakdownGenerateResponse
    func compileBrainDump(request: BrainDumpCompileRequest) async throws -> BrainDumpCompileResponse
    func suggestDecisions(request: DecisionRecommendRequest) async throws -> DecisionRecommendResponse
    func reconcileUsage(request: UsageReconcileRequest) async throws -> UsageReconcileResponse
}
```

Note: `createAnonymousSession` return type changes from `AnonymousSessionResponse` to `SessionResponse` (the rename). Update `NetworkAIBackendClient.createAnonymousSession()` return type accordingly. Also update any test stubs or mocks that implement this protocol.

- [ ] **Step 5: Build to verify compilation**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (with stub implementations if needed — add `fatalError("Not implemented")` for new protocol methods in `NetworkAIBackendClient`)

- [ ] **Step 6: Commit**

```bash
git add ios/Offload/Data/Networking/AIBackendContracts.swift ios/Offload/Data/Networking/AIBackendClient.swift
git commit -m "feat(auth): add Apple session and refresh contracts, rename SessionResponse"
```

---

## Task 6: KeychainSessionTokenStore

**Files:**
- Create: `ios/Offload/Data/Networking/KeychainSessionTokenStore.swift`

- [ ] **Step 1: Create KeychainSessionTokenStore**

Create `ios/Offload/Data/Networking/KeychainSessionTokenStore.swift`:

```swift
/// Keychain-backed session token persistence.
/// Stores session token and expiry date so they survive app termination.

import Foundation
import Security

final class KeychainSessionTokenStore: SessionTokenStore {
    private let service = "wc.Offload.session"
    private let tokenKey = "session_token"
    private let expiryKey = "session_expiry"

    var token: String? {
        get { read(key: tokenKey) }
        set {
            if let value = newValue {
                save(key: tokenKey, value: value)
            } else {
                delete(key: tokenKey)
            }
        }
    }

    var expiresAt: Date? {
        get {
            guard let string = read(key: expiryKey) else { return nil }
            return ISO8601DateFormatter().date(from: string)
        }
        set {
            if let value = newValue {
                save(key: expiryKey, value: ISO8601DateFormatter().string(from: value))
            } else {
                delete(key: expiryKey)
            }
        }
    }

    func clear() {
        delete(key: tokenKey)
        delete(key: expiryKey)
    }

    // MARK: - Keychain helpers

    private func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Offload/Data/Networking/KeychainSessionTokenStore.swift
git commit -m "feat(auth): add Keychain-backed SessionTokenStore"
```

---

## Task 7: AuthManager

**Files:**
- Create: `ios/Offload/Data/Services/AuthManager.swift`

- [ ] **Step 1: Create AuthManager**

Create `ios/Offload/Data/Services/AuthManager.swift`:

```swift
/// Manages Sign in with Apple authentication lifecycle.
/// Owns auth state, Keychain persistence, and session token management.

import AuthenticationServices
import Foundation
import Security

struct AppleUser {
    let userId: String
    let fullName: String?
    let email: String?
}

enum AuthState {
    case signedOut
    case signingIn
    case signedIn(AppleUser)
}

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var state: AuthState = .signedOut

    private let keychainService = "wc.Offload.auth"
    private let userIdKey = "apple_user_id"
    private let fullNameKey = "apple_full_name"
    private let emailKey = "apple_email"

    /// Check Keychain for existing credentials on launch.
    func restoreSession() async {
        guard let userId = readKeychain(key: userIdKey) else { return }

        let credentialState = await checkCredentialState(userId: userId)
        switch credentialState {
        case .authorized:
            let user = AppleUser(
                userId: userId,
                fullName: readKeychain(key: fullNameKey),
                email: readKeychain(key: emailKey)
            )
            state = .signedIn(user)
        case .revoked, .notFound:
            clearKeychain()
            state = .signedOut
        default:
            state = .signedOut
        }
    }

    /// Handle successful Sign in with Apple credential.
    func handleSignInResult(credential: ASAuthorizationAppleIDCredential) {
        let userId = credential.user
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let email = credential.email

        // Persist to Keychain
        saveKeychain(key: userIdKey, value: userId)
        if !fullName.isEmpty {
            saveKeychain(key: fullNameKey, value: fullName)
        }
        if let email {
            saveKeychain(key: emailKey, value: email)
        }

        let user = AppleUser(
            userId: userId,
            fullName: fullName.isEmpty ? readKeychain(key: fullNameKey) : fullName,
            email: email ?? readKeychain(key: emailKey)
        )
        state = .signedIn(user)
    }

    /// Get the identity token from a credential for backend exchange.
    func identityToken(from credential: ASAuthorizationAppleIDCredential) -> String? {
        guard let data = credential.identityToken else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Sign out: clear Keychain and reset state.
    func signOut() {
        clearKeychain()
        state = .signedOut
    }

    /// Current user, if signed in.
    var currentUser: AppleUser? {
        if case .signedIn(let user) = state { return user }
        return nil
    }

    /// Whether the user is currently signed in.
    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    // MARK: - Private

    private func checkCredentialState(userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    private func saveKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func clearKeychain() {
        for key in [userIdKey, fullNameKey, emailKey] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Offload/Data/Services/AuthManager.swift
git commit -m "feat(auth): add AuthManager with Sign in with Apple lifecycle"
```

---

## Task 8: Implement createAppleSession and auth-aware refresh in NetworkAIBackendClient

**Files:**
- Modify: `ios/Offload/Data/Networking/AIBackendClient.swift:131-137` (protocol), `:167-178` (createAnonymousSession), `:338-345` (refreshSession)

- [ ] **Step 1: Implement createAppleSession in NetworkAIBackendClient**

In `AIBackendClient.swift`, add the implementations inside `NetworkAIBackendClient`. Follow the existing pattern (use `performRequest`, store token, return response):

```swift
func createAppleSession(request: AppleSessionRequest) async throws -> SessionResponse {
    let response: SessionResponse = try await performRequest(
        path: "/v1/sessions/apple",
        method: "POST",
        body: request,
        headers: [:],
        retryUnauthorized: false
    )
    tokenStore.token = response.sessionToken
    tokenStore.expiresAt = response.expiresAt
    return response
}

func refreshSessionToken(request: SessionRefreshRequest) async throws -> SessionResponse {
    let response: SessionResponse = try await performRequest(
        path: "/v1/sessions/refresh",
        method: "POST",
        body: request,
        headers: [:],
        retryUnauthorized: false
    )
    tokenStore.token = response.sessionToken
    tokenStore.expiresAt = response.expiresAt
    return response
}
```

- [ ] **Step 2: Update refreshSession() to be auth-aware**

Replace the existing private `refreshSession()` (line 338) to try refresh first, fall back to anonymous:

```swift
private func refreshSession() async throws {
    // Try token refresh first (works for both anonymous and apple sessions)
    if let existingToken = tokenStore.token {
        do {
            let request = SessionRefreshRequest(
                sessionToken: existingToken,
                installId: installIDProvider()
            )
            _ = try await refreshSessionToken(request: request)
            return
        } catch {
            // Refresh failed, fall back to creating new anonymous session
        }
    }
    let anonRequest = AnonymousSessionRequest(
        installId: installIDProvider(),
        appVersion: appVersionProvider(),
        platform: platformProvider()
    )
    _ = try await createAnonymousSession(request: anonRequest)
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/Offload/Data/Networking/AIBackendClient.swift
git commit -m "feat(auth): add Apple session creation and auth-aware token refresh"
```

---

## Task 9: Extract TagManagementView from SettingsView

**Files:**
- Create: `ios/Offload/Features/Settings/TagManagementView.swift`
- Reference: `ios/Offload/Features/Settings/SettingsView.swift:100-225`

- [ ] **Step 1: Create TagManagementView.swift**

Extract `TagManagementView` (lines 100-177) and `AddTagSheet` (lines 181-225) from SettingsView.swift into a new file. Copy them exactly as-is, adding the necessary imports:

```swift
/// Tag management views extracted from SettingsView.
/// Provides list, delete, and add functionality for tags.

import SwiftUI

struct TagManagementView: View {
    // ... exact copy from SettingsView.swift lines 100-177
}

struct AddTagSheet: View {
    // ... exact copy from SettingsView.swift lines 181-225
}
```

Read `SettingsView.swift` lines 100-225 for the exact code. Preserve all theme tokens, environment injections, and accessibility annotations.

- [ ] **Step 2: Remove TagManagementView and AddTagSheet from SettingsView.swift**

Delete the `TagManagementView` (lines 100-177) and `AddTagSheet` (lines 181-225) structs from `SettingsView.swift` to avoid duplicate symbols. Keep the `SettingsView` struct itself intact for now (it will be deleted in Task 11). Update any `NavigationLink` references in `SettingsView` to point to the extracted `TagManagementView`.

- [ ] **Step 3: Build to verify both files compile**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/Offload/Features/Settings/TagManagementView.swift ios/Offload/Features/Settings/SettingsView.swift
git commit -m "refactor(settings): extract TagManagementView and AddTagSheet to own file"
```

---

## Task 10: Rewrite AccountView

**Files:**
- Rewrite: `ios/Offload/Features/Settings/AccountView.swift`

- [ ] **Step 1: Rewrite AccountView with signed-out and signed-in states**

Replace the entire contents of `AccountView.swift`. The view switches on `AuthManager.state`:

- **Signed out**: centered hero with Sign in with Apple button
- **Signed in**: scrollable flat card sections (profile, usage, cloud AI, appearance, tags, about, sign out)

Key implementation notes:
- Use `@EnvironmentObject private var authManager: AuthManager`
- Use `@EnvironmentObject private var themeManager: ThemeManager`
- Use `@Environment(\.colorScheme) private var colorScheme`
- Use `@Environment(\.accessibilityReduceMotion) private var reduceMotion`
- Profile card: accent gradient with `CardSurface`, initial avatar
- Usage card: custom progress bars using `Theme.Colors.accentPrimary/accentSecondary` for bar fill, `Theme.Surface.card` for track
- Cloud AI toggle: reads `UserDefaultsCloudAIConsentStore`
- Appearance: inline picker (moved from SettingsView)
- Tags: `NavigationLink` to `TagManagementView`
- About: version from `Bundle.main`, links as `Button` rows
- Sign out: `Button` with `.alert` confirmation
- Sign in with Apple: `SignInWithAppleButton` from `AuthenticationServices`, handle result in `authManager.handleSignInResult`
- All cards use `CardSurface` from `DesignSystem/Components.swift`
- All text uses `Theme.Typography.*`
- All spacing uses `Theme.Spacing.*`
- All colors use `Theme.Colors.*` — never hardcode
- Add `.accessibilityLabel` on interactive elements

This is a large view — implement section by section, extracting private subviews for each card (e.g., `ProfileCard`, `UsageCard`, `CloudAICard`, etc.) to keep the body readable.

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Offload/Features/Settings/AccountView.swift
git commit -m "feat(account): rewrite AccountView with auth states and full sections"
```

---

## Task 11: Wire up AuthManager and clean up SettingsView

**Files:**
- Modify: `ios/Offload/App/AppRootView.swift`
- Modify: `ios/Offload/App/MainTabView.swift`
- Delete: `ios/Offload/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Inject AuthManager in AppRootView**

In `AppRootView.swift`, add:

```swift
@StateObject private var authManager = AuthManager()
```

Pass it to `MainTabView`:

```swift
MainTabView()
    .environmentObject(authManager)
    // ... existing environment injections
```

Add session restore in the `.task` block:

```swift
.task {
    await authManager.restoreSession()
}
```

- [ ] **Step 2: Remove SettingsView references from MainTabView**

In `MainTabView.swift`, remove any imports or references to `SettingsView`. The Account tab already renders `AccountView()` — just ensure it does not reference `SettingsView` anywhere.

- [ ] **Step 3: Delete SettingsView.swift**

Run: `rm ios/Offload/Features/Settings/SettingsView.swift`

Also remove it from the Xcode project file if needed (it should auto-detect the missing file).

- [ ] **Step 4: Update NetworkAIBackendClient to use KeychainSessionTokenStore**

In `AIBackendClient.swift`, where `InMemorySessionTokenStore` is instantiated, replace with `KeychainSessionTokenStore()`. This is typically in the initializer or factory method.

- [ ] **Step 5: Build to verify everything compiles**

Run: `xcodebuild build -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Run tests**

Run: `xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -20`
Expected: Tests pass (existing tests should not break)

- [ ] **Step 7: Commit**

```bash
git add ios/Offload/App/AppRootView.swift ios/Offload/App/MainTabView.swift ios/Offload/Data/Networking/AIBackendClient.swift
git rm ios/Offload/Features/Settings/SettingsView.swift
git commit -m "feat(account): wire AuthManager injection, replace InMemorySessionTokenStore, delete SettingsView"
```

---

## Task 12: Final integration test

**Files:**
- All files from previous tasks

- [ ] **Step 1: Run full backend test suite**

Run: `cd backend/api && python -m pytest tests/ -v --tb=short`
Expected: ALL PASS

- [ ] **Step 2: Run backend lint and type check**

Run: `just backend-check`
Expected: PASS

- [ ] **Step 3: Run iOS build**

Run: `just build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run iOS tests**

Run: `xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' 2>&1 | tail -20`
Expected: Tests pass

- [ ] **Step 5: Run lint**

Run: `just lint`
Expected: PASS

- [ ] **Step 6: Commit any fixups**

If any lint/test issues were found and fixed, commit them:

```bash
git add -A
git commit -m "fix(account): address lint and test issues from integration"
```
