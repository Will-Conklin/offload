from __future__ import annotations

from fastapi import APIRouter, Depends

from offload_backend.config import Settings
from offload_backend.dependencies import get_app_settings, get_token_manager
from offload_backend.schemas import AnonymousSessionRequest, AnonymousSessionResponse
from offload_backend.security import TokenManager

router = APIRouter()


@router.post("/sessions/anonymous", response_model=AnonymousSessionResponse)
def create_anonymous_session(
    request: AnonymousSessionRequest,
    token_manager: TokenManager = Depends(get_token_manager),
    settings: Settings = Depends(get_app_settings),
) -> AnonymousSessionResponse:
    _ = (request.app_version, request.platform)
    claims = token_manager.issue_session(
        install_id=request.install_id,
        ttl_seconds=settings.session_ttl_seconds,
    )
    return AnonymousSessionResponse(
        session_token=token_manager.encode(claims),
        expires_at=claims.expires_at,
    )
