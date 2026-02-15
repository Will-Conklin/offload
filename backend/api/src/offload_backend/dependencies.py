from __future__ import annotations

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
from offload_backend.usage_store import InMemoryUsageStore

bearer_scheme = HTTPBearer(auto_error=False)


def get_request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "unknown")


def get_app_settings() -> Settings:
    return get_settings()


def get_token_manager(settings: Settings = Depends(get_app_settings)) -> TokenManager:
    return TokenManager(secret=settings.session_secret)


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
