from __future__ import annotations

import base64
import hashlib
import hmac
import json
from datetime import UTC, datetime, timedelta

from pydantic import BaseModel, ConfigDict


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
    def __init__(self, secret: str):
        self._secret = secret.encode("utf-8")

    def issue_session(
        self,
        install_id: str,
        ttl_seconds: int,
        now: datetime | None = None,
    ) -> SessionClaims:
        now = now or datetime.now(UTC)
        return SessionClaims(install_id=install_id, expires_at=now + timedelta(seconds=ttl_seconds))

    def encode(self, claims: SessionClaims) -> str:
        payload = {
            "install_id": claims.install_id,
            "exp": int(claims.expires_at.timestamp()),
        }
        payload_bytes = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        payload_b64 = base64.urlsafe_b64encode(payload_bytes).decode("utf-8").rstrip("=")
        signature = hmac.new(self._secret, payload_b64.encode("utf-8"), hashlib.sha256).digest()
        signature_b64 = base64.urlsafe_b64encode(signature).decode("utf-8").rstrip("=")
        return f"{payload_b64}.{signature_b64}"

    def decode(self, token: str) -> SessionClaims:
        try:
            payload_b64, signature_b64 = token.split(".", maxsplit=1)
        except ValueError as exc:
            raise InvalidTokenError("Malformed session token") from exc

        expected_signature = hmac.new(
            self._secret,
            payload_b64.encode("utf-8"),
            hashlib.sha256,
        ).digest()
        provided_signature = _urlsafe_b64decode(signature_b64)

        if not hmac.compare_digest(expected_signature, provided_signature):
            raise InvalidTokenError("Token signature mismatch")

        payload_bytes = _urlsafe_b64decode(payload_b64)
        try:
            payload = json.loads(payload_bytes.decode("utf-8"))
            expires_at = datetime.fromtimestamp(int(payload["exp"]), tz=UTC)
            install_id = str(payload["install_id"])
        except (KeyError, ValueError, json.JSONDecodeError) as exc:
            raise InvalidTokenError("Invalid token payload") from exc

        if expires_at <= datetime.now(UTC):
            raise ExpiredTokenError("Token expired")

        return SessionClaims(install_id=install_id, expires_at=expires_at)


def _urlsafe_b64decode(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(f"{value}{padding}".encode())
