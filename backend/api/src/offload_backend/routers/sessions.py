from __future__ import annotations

from fastapi import APIRouter, Depends, Request

from offload_backend.config import Settings
from offload_backend.dependencies import (
    enforce_session_issuance_rate_limit,
    get_app_settings,
    get_session_rate_limiter,
    get_token_manager,
)
from offload_backend.schemas import AnonymousSessionRequest, AnonymousSessionResponse
from offload_backend.security import TokenManager
from offload_backend.session_rate_limiter import SessionRateLimiter

router = APIRouter()


@router.post("/sessions/anonymous", response_model=AnonymousSessionResponse)
def create_anonymous_session(
    payload: AnonymousSessionRequest,
    request: Request,
    token_manager: TokenManager = Depends(get_token_manager),
    limiter: SessionRateLimiter = Depends(get_session_rate_limiter),
    settings: Settings = Depends(get_app_settings),
) -> AnonymousSessionResponse:
    _ = (payload.app_version, payload.platform)
    enforce_session_issuance_rate_limit(
        install_id=payload.install_id,
        request=request,
        limiter=limiter,
    )
    claims = token_manager.issue_session(
        install_id=payload.install_id,
        ttl_seconds=settings.session_ttl_seconds,
    )
    return AnonymousSessionResponse(
        session_token=token_manager.encode(claims),
        expires_at=claims.expires_at,
    )
