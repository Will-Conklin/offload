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
from offload_backend.errors import APIException
from offload_backend.providers.base import (
    AIProvider,
    ProviderRequestError,
    ProviderResponseError,
    ProviderTimeout,
    ProviderUnavailable,
)
from offload_backend.schemas import (
    BrainDumpCompileRequest,
    BrainDumpCompileResponse,
    BrainDumpItem,
    BrainDumpUsage,
)
from offload_backend.security import SessionClaims
from offload_backend.session_rate_limiter import SessionRateLimiter
from offload_backend.usage_store import UsageStore

router = APIRouter()


def _request_content_size_chars(request: BrainDumpCompileRequest) -> int:
    return len(request.input_text) + sum(len(h) for h in request.context_hints)


@router.post("/ai/braindump/compile", response_model=BrainDumpCompileResponse)
async def compile_brain_dump(
    request: BrainDumpCompileRequest,
    http_request: Request,
    claims: SessionClaims = Depends(get_session_claims),
    _: None = Depends(require_cloud_opt_in),
    _quota: None = Depends(enforce_ai_quota),
    provider: AIProvider = Depends(get_provider),
    settings: Settings = Depends(get_app_settings),
    limiter: SessionRateLimiter = Depends(get_ai_inference_rate_limiter),
    usage_store: UsageStore = Depends(get_usage_store),
) -> BrainDumpCompileResponse:
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

    try:
        result = await provider.compile_brain_dump(
            input_text=request.input_text,
            context_hints=request.context_hints,
        )
    except ProviderTimeout as exc:
        raise APIException(
            status_code=504,
            code="provider_timeout",
            message="Provider timeout",
        ) from exc
    except ProviderUnavailable as exc:
        raise APIException(
            status_code=503,
            code="provider_unavailable",
            message="Provider unavailable",
        ) from exc
    except ProviderResponseError as exc:
        raise APIException(
            status_code=502,
            code="provider_invalid_response",
            message="Provider returned invalid response",
        ) from exc
    except ProviderRequestError as exc:
        raise APIException(
            status_code=502,
            code="provider_request_failed",
            message="Provider request failed",
        ) from exc

    latency_ms = max(0, int((datetime.now(UTC) - started_at).total_seconds() * 1000))
    usage_store.increment(install_id=claims.install_id, feature="braindump")

    return BrainDumpCompileResponse(
        items=[BrainDumpItem.model_validate(item) for item in result.items],
        provider=provider.provider_name,
        latency_ms=latency_ms,
        usage=BrainDumpUsage(input_tokens=result.input_tokens, output_tokens=result.output_tokens),
    )
