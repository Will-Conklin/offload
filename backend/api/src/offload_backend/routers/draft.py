from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request

from offload_backend.config import Settings
from offload_backend.dependencies import (
    enforce_ai_inference_rate_limit,
    enforce_ai_quota,
    get_ai_inference_rate_limiter,
    get_app_settings,
    get_provider,
    get_session_claims,
    get_usage_store,
    require_cloud_opt_in,
)
from offload_backend.errors import APIException, call_provider
from offload_backend.providers.base import AIProvider
from offload_backend.schemas import (
    CommunicationDraftRequest,
    CommunicationDraftResponse,
    CommunicationDraftUsage,
)
from offload_backend.security import SessionClaims
from offload_backend.session_rate_limiter import SessionRateLimiter
from offload_backend.usage_store import UsageStore

router = APIRouter()


def _request_content_size_chars(request: CommunicationDraftRequest) -> int:
    return (
        len(request.input_text)
        + len(request.channel)
        + len(request.contact_name or "")
        + sum(len(h) for h in request.context_hints)
    )


@router.post(
    "/ai/communication/draft",
    response_model=CommunicationDraftResponse,
)
async def draft_communication(
    request: CommunicationDraftRequest,
    http_request: Request,
    claims: SessionClaims = Depends(get_session_claims),
    _: None = Depends(require_cloud_opt_in),
    _quota: None = Depends(enforce_ai_quota),
    provider: AIProvider = Depends(get_provider),
    settings: Settings = Depends(get_app_settings),
    limiter: SessionRateLimiter = Depends(get_ai_inference_rate_limiter),
    usage_store: UsageStore = Depends(get_usage_store),
) -> CommunicationDraftResponse:
    """Generate a draft message for a communication item."""
    enforce_ai_inference_rate_limit(
        install_id=claims.install_id, request=http_request, limiter=limiter
    )
    if _request_content_size_chars(request) > settings.max_input_chars:
        raise APIException(
            status_code=413,
            code="request_too_large",
            message=f"Request content exceeds max size of {settings.max_input_chars} characters",
        )

    started_at = datetime.now(UTC)

    result = await call_provider(
        lambda: provider.draft_communication(
            input_text=request.input_text,
            channel=request.channel,
            contact_name=request.contact_name,
            context_hints=request.context_hints,
        )
    )

    latency_ms = max(0, int((datetime.now(UTC) - started_at).total_seconds() * 1000))
    usage_store.increment(install_id=claims.install_id, feature="draft")

    return CommunicationDraftResponse(
        draft_text=result.draft_text,
        tone=result.tone,
        provider=provider.provider_name,
        latency_ms=latency_ms,
        usage=CommunicationDraftUsage(
            input_tokens=result.input_tokens,
            output_tokens=result.output_tokens,
        ),
    )
