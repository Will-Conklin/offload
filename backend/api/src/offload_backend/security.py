from __future__ import annotations

import base64
import binascii
import hashlib
import hmac
import json
from collections.abc import Callable, Mapping
from datetime import UTC, datetime, timedelta

from pydantic import BaseModel, ConfigDict

TOKEN_VERSION = 2
REQUIRED_V2_CLAIMS = frozenset({"v", "kid", "iat", "nbf", "iss", "aud", "exp", "install_id"})


class TokenError(Exception):
    pass


class InvalidTokenError(TokenError):
    pass


class ExpiredTokenError(TokenError):
    pass


class SessionClaims(BaseModel):
    model_config = ConfigDict(frozen=True)

    install_id: str
    expires_at: datetime


class TokenManager:
    def __init__(
        self,
        secret: str,
        *,
        issuer: str = "offload-backend",
        audience: str = "offload-ios",
        active_kid: str = "v2-default",
        signing_keys: Mapping[str, str] | None = None,
        now_provider: Callable[[], datetime] | None = None,
    ):
        self._issuer = issuer.strip()
        self._audience = audience.strip()
        self._active_kid = active_kid.strip()
        if not self._issuer or not self._audience or not self._active_kid:
            raise ValueError("Token issuer, audience, and active_kid must be non-empty")

        self._now_provider = now_provider or (lambda: datetime.now(UTC))
        self._signing_keys = _build_signing_keys(
            secret=secret,
            active_kid=self._active_kid,
            signing_keys=signing_keys,
        )

    def issue_session(
        self,
        install_id: str,
        ttl_seconds: int,
        now: datetime | None = None,
    ) -> SessionClaims:
        now = now or self._now_provider()
        return SessionClaims(install_id=install_id, expires_at=now + timedelta(seconds=ttl_seconds))

    def encode(self, claims: SessionClaims) -> str:
        issued_at = int(self._now_provider().timestamp())
        payload = {
            "v": TOKEN_VERSION,
            "kid": self._active_kid,
            "iat": issued_at,
            "nbf": issued_at,
            "iss": self._issuer,
            "aud": self._audience,
            "install_id": claims.install_id,
            "exp": int(claims.expires_at.timestamp()),
        }
        payload_b64 = _encode_payload(payload)
        signature = hmac.new(
            self._signing_keys[self._active_kid],
            payload_b64.encode("utf-8"),
            hashlib.sha256,
        ).digest()
        signature_b64 = base64.urlsafe_b64encode(signature).decode("utf-8").rstrip("=")
        return f"{payload_b64}.{signature_b64}"

    def decode(self, token: str) -> SessionClaims:
        payload_b64, signature_b64 = _split_token(token)
        payload = _decode_payload(payload_b64)
        kid = _parse_key_id(payload)
        signing_key = self._signing_keys.get(kid)
        if signing_key is None:
            raise InvalidTokenError("Unknown token key id")

        expected_signature = hmac.new(
            signing_key,
            payload_b64.encode("utf-8"),
            hashlib.sha256,
        ).digest()
        provided_signature = _urlsafe_b64decode(signature_b64)

        if not hmac.compare_digest(expected_signature, provided_signature):
            raise InvalidTokenError("Token signature mismatch")

        return self._parse_v2_claims(payload)

    def _parse_v2_claims(self, payload: dict[str, object]) -> SessionClaims:
        missing_claims = REQUIRED_V2_CLAIMS.difference(payload.keys())
        if missing_claims:
            raise InvalidTokenError("Missing token claims")

        version = _require_int(payload, "v")
        key_id = _require_str(payload, "kid")
        issued_at = datetime.fromtimestamp(_require_int(payload, "iat"), tz=UTC)
        not_before = datetime.fromtimestamp(_require_int(payload, "nbf"), tz=UTC)
        issuer = _require_str(payload, "iss")
        audience = _require_str(payload, "aud")
        expires_at = datetime.fromtimestamp(_require_int(payload, "exp"), tz=UTC)
        install_id = _require_str(payload, "install_id")

        if version != TOKEN_VERSION:
            raise InvalidTokenError("Unsupported token version")
        if issuer != self._issuer:
            raise InvalidTokenError("Token issuer mismatch")
        if audience != self._audience:
            raise InvalidTokenError("Token audience mismatch")
        if key_id not in self._signing_keys:
            raise InvalidTokenError("Unknown token key id")
        if not_before < issued_at:
            raise InvalidTokenError("Invalid token timing claims")

        now = self._now_provider()
        if now < not_before:
            raise InvalidTokenError("Token not active yet")
        if expires_at <= now:
            raise ExpiredTokenError("Token expired")

        return SessionClaims(install_id=install_id, expires_at=expires_at)


def _build_signing_keys(
    *,
    secret: str,
    active_kid: str,
    signing_keys: Mapping[str, str] | None,
) -> dict[str, bytes]:
    normalized: dict[str, bytes] = {}
    if signing_keys:
        for kid, key in signing_keys.items():
            normalized_kid = kid.strip()
            normalized_key = key.strip()
            if not normalized_kid or not normalized_key:
                raise ValueError("Token signing keys must contain non-empty key IDs and values")
            normalized[normalized_kid] = normalized_key.encode("utf-8")

    if active_kid not in normalized:
        fallback_secret = secret.strip()
        if not fallback_secret:
            raise ValueError("Missing key material for active token key ID")
        normalized[active_kid] = fallback_secret.encode("utf-8")

    return normalized


def _encode_payload(payload: dict[str, object]) -> str:
    payload_bytes = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return base64.urlsafe_b64encode(payload_bytes).decode("utf-8").rstrip("=")


def _split_token(token: str) -> tuple[str, str]:
    try:
        payload_b64, signature_b64 = token.split(".", maxsplit=1)
    except ValueError as exc:
        raise InvalidTokenError("Malformed session token") from exc
    return payload_b64, signature_b64


def _decode_payload(payload_b64: str) -> dict[str, object]:
    payload_bytes = _urlsafe_b64decode(payload_b64)
    try:
        payload = json.loads(payload_bytes.decode("utf-8"))
    except (TypeError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise InvalidTokenError("Invalid token payload") from exc
    if not isinstance(payload, dict):
        raise InvalidTokenError("Invalid token payload")
    return payload


def _parse_key_id(payload: dict[str, object]) -> str:
    key_id = _require_str(payload, "kid")
    if not key_id:
        raise InvalidTokenError("Invalid token payload")
    return key_id


def _require_int(payload: dict[str, object], key: str) -> int:
    if key not in payload:
        raise InvalidTokenError("Invalid token payload")
    value = payload[key]
    try:
        if isinstance(value, int):
            return value
        if isinstance(value, (str, float)):
            return int(value)
        raise TypeError
    except (TypeError, ValueError) as exc:
        raise InvalidTokenError("Invalid token payload") from exc


def _require_str(payload: dict[str, object], key: str) -> str:
    if key not in payload:
        raise InvalidTokenError("Invalid token payload")
    value = payload[key]
    try:
        text = str(value)
    except (TypeError, ValueError) as exc:
        raise InvalidTokenError("Invalid token payload") from exc
    if not text:
        raise InvalidTokenError("Invalid token payload")
    return text


def _urlsafe_b64decode(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    try:
        return base64.urlsafe_b64decode(f"{value}{padding}".encode())
    except (binascii.Error, ValueError) as exc:
        raise InvalidTokenError("Malformed session token encoding") from exc
