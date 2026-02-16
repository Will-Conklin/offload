import base64
import hashlib
import hmac

import pytest


def _build_signed_token(payload_segment: str, secret: str = "test-secret") -> str:
    signature = hmac.new(
        secret.encode("utf-8"),
        payload_segment.encode("utf-8"),
        hashlib.sha256,
    ).digest()
    signature_segment = base64.urlsafe_b64encode(signature).decode("utf-8").rstrip("=")
    return f"{payload_segment}.{signature_segment}"


def test_session_issuance_returns_token_and_expiry(client):
    response = client.post(
        "/v1/sessions/anonymous",
        json={"install_id": "install-12345", "app_version": "1.0", "platform": "ios"},
    )

    assert response.status_code == 200
    body = response.json()
    assert isinstance(body["session_token"], str)
    assert body["session_token"]
    assert body["expires_at"]


def test_malformed_base64_payload_token_is_rejected(post_usage_reconcile):
    token = _build_signed_token(payload_segment="%%%")
    response = post_usage_reconcile(authorization=f"Bearer {token}")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


@pytest.mark.parametrize(
    "authorization",
    [
        "Bearer invalid-token",
        "Bearer payload.signature.extra",
        "Bearer .",
        "Bearer payload.",
        "Bearer .signature",
        "Bearer payload.!@#$",
    ],
)
def test_malformed_token_segments_are_rejected(post_usage_reconcile, authorization):
    response = post_usage_reconcile(authorization=authorization)

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "invalid_token"


def test_usage_auth_error_code_contract_is_stable(
    post_usage_reconcile,
    create_expired_session_token,
):
    expired_token = create_expired_session_token()

    missing_token = post_usage_reconcile()
    invalid_token = post_usage_reconcile(authorization="Bearer invalid-token")
    expired = post_usage_reconcile(authorization=f"Bearer {expired_token}")

    assert missing_token.status_code == 401
    assert missing_token.json()["error"]["code"] == "unauthorized"

    assert invalid_token.status_code == 401
    assert invalid_token.json()["error"]["code"] == "invalid_token"

    assert expired.status_code == 401
    assert expired.json()["error"]["code"] == "expired_token"


def test_breakdown_auth_error_code_contract_is_stable(
    post_breakdown_generate,
    create_expired_session_token,
):
    expired_token = create_expired_session_token()

    missing_token = post_breakdown_generate()
    invalid_token = post_breakdown_generate(authorization="Bearer invalid-token")
    expired = post_breakdown_generate(authorization=f"Bearer {expired_token}")

    assert missing_token.status_code == 401
    assert missing_token.json()["error"]["code"] == "unauthorized"

    assert invalid_token.status_code == 401
    assert invalid_token.json()["error"]["code"] == "invalid_token"

    assert expired.status_code == 401
    assert expired.json()["error"]["code"] == "expired_token"


def test_valid_token_allows_protected_endpoint(create_session_token, post_usage_reconcile):
    token = create_session_token()

    response = post_usage_reconcile(
        authorization=f"Bearer {token}",
        local_count=3,
    )

    assert response.status_code == 200
    assert response.json()["server_count"] == 3
