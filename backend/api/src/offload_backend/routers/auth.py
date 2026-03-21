from __future__ import annotations

import logging

from fastapi import APIRouter, Depends

from offload_backend.apple_auth import AppleTokenValidationError, AppleTokenValidator
from offload_backend.config import Settings
from offload_backend.dependencies import (
    get_app_settings,
    get_apple_validator,
    get_token_manager,
    get_user_store,
)
from offload_backend.errors import APIException
from offload_backend.schemas import AppleAuthRequest, AppleAuthResponse
from offload_backend.security import TokenManager
from offload_backend.user_store import UserStore

logger = logging.getLogger("offload_backend")

router = APIRouter()


@router.post("/auth/apple", response_model=AppleAuthResponse)
def sign_in_with_apple(
    body: AppleAuthRequest,
    token_manager: TokenManager = Depends(get_token_manager),
    user_store: UserStore = Depends(get_user_store),
    apple_validator: AppleTokenValidator = Depends(get_apple_validator),
    settings: Settings = Depends(get_app_settings),
) -> AppleAuthResponse:
    try:
        apple_sub = apple_validator.validate(body.apple_identity_token)
    except AppleTokenValidationError as exc:
        logger.warning("apple_token_validation_failed", extra={"error": str(exc)})
        raise APIException(
            status_code=401,
            code="invalid_apple_token",
            message="Apple identity token validation failed",
        ) from exc

    user = user_store.upsert_by_apple_id(
        apple_user_id=apple_sub,
        install_id=body.install_id,
        display_name=body.display_name,
    )

    claims = token_manager.issue_session(
        install_id=body.install_id,
        ttl_seconds=settings.session_ttl_seconds,
        user_id=user.user_id,
    )

    return AppleAuthResponse(
        session_token=token_manager.encode(claims),
        expires_at=claims.expires_at,
        user_id=user.user_id,
    )
