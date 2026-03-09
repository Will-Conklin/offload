from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request

from offload_backend.config import Settings
from offload_backend.dependencies import (
    enforce_ai_inference_rate_limit,
    get_ai_inference_rate_limiter,
    get_app_settings,
    get_provider,
    get_session_claims,
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
    DecisionOption,
    DecisionRecommendRequest,
    DecisionRecommendResponse,
    DecisionUsage,
)
from offload_backend.security import SessionClaims
from offload_backend.session_rate_limiter import SessionRateLimiter

router = APIRouter()


def _request_content_size_chars(request: DecisionRecommendRequest) -> int:
    answers_size = sum(
        len(a.question) + len(a.answer) for a in request.clarifying_answers
    )
    return (
        len(request.input_text)
        + sum(len(h) for h in request.context_hints)
        + answers_size
    )


@router.post("/ai/decide/recommend", response_model=DecisionRecommendResponse)
async def recommend_decision(
    request: DecisionRecommendRequest,
    http_request: Request,
    claims: SessionClaims = Depends(get_session_claims),
    _: None = Depends(require_cloud_opt_in),
    provider: AIProvider = Depends(get_provider),
    settings: Settings = Depends(get_app_settings),
    limiter: SessionRateLimiter = Depends(get_ai_inference_rate_limiter),
) -> DecisionRecommendResponse:
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
        result = await provider.suggest_decisions(
            input_text=request.input_text,
            context_hints=request.context_hints,
            clarifying_answers=[
                {"question": a.question, "answer": a.answer}
                for a in request.clarifying_answers
            ],
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

    return DecisionRecommendResponse(
        options=[DecisionOption.model_validate(opt) for opt in result.options],
        clarifying_questions=result.clarifying_questions[:2],
        provider="openai",
        latency_ms=latency_ms,
        usage=DecisionUsage(input_tokens=result.input_tokens, output_tokens=result.output_tokens),
    )
