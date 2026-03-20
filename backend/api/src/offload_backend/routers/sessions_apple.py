"""Apple Sign-In session creation and token refresh endpoints."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request

from offload_backend.apple_jwt import verify_apple_identity_token
from offload_backend.config import Settings
from offload_backend.dependencies import (
    enforce_session_issuance_rate_limit,
    get_app_settings,
    get_session_rate_limiter,
    get_token_manager,
)
from offload_backend.errors import APIException
from offload_backend.schemas import AppleSessionRequest, SessionRefreshRequest, SessionResponse
from offload_backend.security import TokenError, TokenManager
from offload_backend.session_rate_limiter import SessionRateLimiter

router = APIRouter()

_MAX_REFRESH_AGE_DAYS = 30


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
            body.identity_token,
            expected_audience=settings.apple_bundle_id,
        )
    except ValueError as exc:
        raise APIException(
            status_code=401,
            code='invalid_apple_token',
            message=str(exc),
        ) from exc

    claims = token_manager.issue_session(
        install_id=body.install_id,
        ttl_seconds=settings.session_ttl_seconds,
        apple_user_id=apple_user_id,
    )
    return SessionResponse(
        session_token=token_manager.encode(claims),
        expires_at=claims.expires_at,
    )


@router.post('/sessions/refresh', response_model=SessionResponse)
async def refresh_session(
    body: SessionRefreshRequest,
    request: Request,
    settings: Settings = Depends(get_app_settings),
    token_manager: TokenManager = Depends(get_token_manager),
    limiter: SessionRateLimiter = Depends(get_session_rate_limiter),
) -> SessionResponse:
    """Refresh an expired session token (valid signature required)."""
    enforce_session_issuance_rate_limit(
        install_id=body.install_id,
        request=request,
        limiter=limiter,
    )

    try:
        old_claims = token_manager.decode(body.session_token, allow_expired=True)
    except TokenError as exc:
        raise APIException(
            status_code=401,
            code='invalid_token',
            message='Invalid session token',
        ) from exc

    if old_claims.install_id != body.install_id:
        raise APIException(
            status_code=401,
            code='install_id_mismatch',
            message='install_id does not match token',
        )

    # Reject tokens older than 30 days
    now = datetime.now(UTC)
    token_age_seconds = (now - old_claims.expires_at).total_seconds() + settings.session_ttl_seconds
    max_age_seconds = _MAX_REFRESH_AGE_DAYS * 86400
    if token_age_seconds > max_age_seconds:
        raise APIException(
            status_code=401,
            code='token_too_old',
            message='Token is too old to refresh',
        )

    new_claims = token_manager.issue_session(
        install_id=old_claims.install_id,
        ttl_seconds=settings.session_ttl_seconds,
        apple_user_id=old_claims.apple_user_id,
    )
    return SessionResponse(
        session_token=token_manager.encode(new_claims),
        expires_at=new_claims.expires_at,
    )
