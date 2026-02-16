import base64
import hashlib
import hmac
import json
from datetime import UTC, datetime, timedelta

import pytest

from offload_backend.security import ExpiredTokenError, SessionClaims, TokenManager

REQUIRED_V2_CLAIMS = {"v", "kid", "iat", "nbf", "iss", "aud", "exp", "install_id"}


def _urlsafe_b64encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).decode("utf-8").rstrip("=")


def _payload_from_token(token: str) -> dict[str, object]:
    payload_segment = token.split(".", maxsplit=1)[0]
    padding = "=" * (-len(payload_segment) % 4)
    payload_bytes = base64.urlsafe_b64decode(f"{payload_segment}{padding}".encode())
    return json.loads(payload_bytes.decode("utf-8"))


def _build_signed_token(payload: dict[str, object], secret: str = "test-secret") -> str:
    payload_segment = _urlsafe_b64encode(
        json.dumps(payload, separators=(",", ":")).encode("utf-8"),
    )
    signature = hmac.new(secret.encode("utf-8"), payload_segment.encode("utf-8"), hashlib.sha256)
    return f"{payload_segment}.{_urlsafe_b64encode(signature.digest())}"


class _ManualClock:
    def __init__(self, start: datetime):
        self._now = start

    def now(self) -> datetime:
        return self._now

    def advance(self, *, seconds: int) -> None:
        self._now += timedelta(seconds=seconds)


def test_session_token_uses_v2_required_claims(create_session_token):
    token = create_session_token()
    payload = _payload_from_token(token)

    assert REQUIRED_V2_CLAIMS.issubset(payload.keys())
    assert payload["v"] == 2
    assert payload["kid"] == "test-kid"
    assert payload["iss"] == "offload-backend-test"
    assert payload["aud"] == "offload-ios-test"


@pytest.mark.parametrize(
    ("claim", "value"),
    [
        ("iss", "wrong-issuer"),
        ("aud", "wrong-audience"),
        ("kid", "unknown-kid"),
    ],
)
def test_token_decode_rejects_invalid_metadata_claims(
    post_usage_reconcile,
    claim: str,
    value: str,
):
    now = datetime(2026, 2, 16, 12, 0, tzinfo=UTC)
    payload = {
        "v": 2,
        "kid": "test-kid",
        "iat": int(now.timestamp()),
        "nbf": int(now.timestamp()),
        "iss": "offload-backend-test",
        "aud": "offload-ios-test",
        "exp": int((now + timedelta(seconds=300)).timestamp()),
        "install_id": "install-12345",
    }
    payload[claim] = value
    token = _build_signed_token(payload, secret="test-secret")

    response = post_usage_reconcile(authorization=f"Bearer {token}")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


def test_legacy_v1_token_is_rejected(post_usage_reconcile):
    legacy_payload = {
        "install_id": "install-12345",
        "exp": int((datetime.now(UTC) + timedelta(seconds=300)).timestamp()),
    }
    token = _build_signed_token(legacy_payload, secret="test-secret")

    response = post_usage_reconcile(authorization=f"Bearer {token}")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


def test_token_manager_issue_session_uses_injected_clock():
    clock = _ManualClock(start=datetime(2026, 2, 16, 12, 0, tzinfo=UTC))
    manager = TokenManager(
        secret="test-secret",
        issuer="offload-backend-test",
        audience="offload-ios-test",
        active_kid="test-kid",
        now_provider=clock.now,
    )

    claims = manager.issue_session(install_id="install-12345", ttl_seconds=120)

    assert claims == SessionClaims(
        install_id="install-12345",
        expires_at=datetime(2026, 2, 16, 12, 2, tzinfo=UTC),
    )


def test_token_manager_decode_uses_injected_clock_for_expiry():
    clock = _ManualClock(start=datetime(2026, 2, 16, 12, 0, tzinfo=UTC))
    manager = TokenManager(
        secret="test-secret",
        issuer="offload-backend-test",
        audience="offload-ios-test",
        active_kid="test-kid",
        now_provider=clock.now,
    )

    claims = SessionClaims(
        install_id="install-12345",
        expires_at=datetime(2026, 2, 16, 12, 0, 1, tzinfo=UTC),
    )
    token = manager.encode(claims)

    clock.advance(seconds=2)
    with pytest.raises(ExpiredTokenError):
        manager.decode(token)
