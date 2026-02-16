from __future__ import annotations

import hashlib
import logging

from fastapi import Depends, Header, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from offload_backend.config import Settings, get_settings
from offload_backend.errors import APIException
from offload_backend.providers.base import AIProvider
from offload_backend.providers.openai_adapter import OpenAIProviderAdapter
from offload_backend.security import (
    ExpiredTokenError,
    InvalidTokenError,
    SessionClaims,
    TokenManager,
)
from offload_backend.session_rate_limiter import (
    InMemorySessionRateLimiter,
    SessionRateLimiter,
    SessionRateLimitExceeded,
)
from offload_backend.usage_store import InMemoryUsageStore

bearer_scheme = HTTPBearer(auto_error=False)
logger = logging.getLogger("offload_backend")


def get_request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "unknown")


def get_app_settings() -> Settings:
    return get_settings()


def get_token_manager(settings: Settings = Depends(get_app_settings)) -> TokenManager:
    return TokenManager(
        secret=settings.session_secret,
        issuer=settings.session_token_issuer,
        audience=settings.session_token_audience,
        active_kid=settings.session_token_active_kid,
        signing_keys=settings.session_signing_keys,
    )


def get_session_claims(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    token_manager: TokenManager = Depends(get_token_manager),
) -> SessionClaims:
    if credentials is None:
        raise APIException(status_code=401, code="unauthorized", message="Missing bearer token")

    try:
        return token_manager.decode(credentials.credentials)
    except ExpiredTokenError as exc:
        raise APIException(
            status_code=401,
            code="expired_token",
            message="Session token expired",
        ) from exc
    except InvalidTokenError as exc:
        raise APIException(
            status_code=401,
            code="invalid_token",
            message="Invalid session token",
        ) from exc


def require_cloud_opt_in(
    opt_in_header: str | None = Header(default=None, alias="X-Offload-Cloud-Opt-In"),
) -> None:
    if opt_in_header is None or opt_in_header.lower() != "true":
        raise APIException(
            status_code=403,
            code="consent_required",
            message="Cloud AI processing requires explicit opt-in",
        )


def get_provider(settings: Settings = Depends(get_app_settings)) -> AIProvider:
    return OpenAIProviderAdapter(settings=settings)


def get_usage_store(request: Request) -> InMemoryUsageStore:
    return request.app.state.usage_store


def get_session_rate_limiter(
    request: Request,
    settings: Settings = Depends(get_app_settings),
) -> SessionRateLimiter:
    limiter = getattr(request.app.state, "session_rate_limiter", None)
    if limiter is None:
        limiter = InMemorySessionRateLimiter(
            limit_per_ip=settings.session_issue_limit_per_ip,
            limit_per_install=settings.session_issue_limit_per_install,
            window_seconds=settings.session_issue_limit_window_seconds,
        )
        request.app.state.session_rate_limiter = limiter
    return limiter


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",", maxsplit=1)[0].strip()
    if request.client is None or request.client.host is None:
        return "unknown"
    return request.client.host


def _install_id_hash(install_id: str) -> str:
    return hashlib.sha256(install_id.encode("utf-8")).hexdigest()[:12]


def enforce_session_issuance_rate_limit(
    *,
    install_id: str,
    request: Request,
    limiter: SessionRateLimiter,
) -> None:
    client_ip = _client_ip(request)
    try:
        limiter.check(client_ip=client_ip, install_id=install_id)
    except SessionRateLimitExceeded as exc:
        logger.info(
            "session_issuance_throttled",
            extra={
                "request_id": get_request_id(request),
                "path": request.url.path,
                "dimension": exc.dimension,
                "retry_after_seconds": exc.retry_after_seconds,
                "install_id_hash": _install_id_hash(install_id),
            },
        )
        raise APIException(
            status_code=429,
            code="session_rate_limited",
            message="Too many session requests; retry later",
        ) from exc
