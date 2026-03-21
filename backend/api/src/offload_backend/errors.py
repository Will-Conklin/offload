from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import TypeVar

from fastapi import Request
from fastapi.responses import JSONResponse

from offload_backend.providers.base import (
    ProviderRequestError,
    ProviderResponseError,
    ProviderTimeout,
    ProviderUnavailable,
)
from offload_backend.schemas import ErrorBody, ErrorEnvelope


class APIException(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        self.status_code = status_code
        self.code = code
        self.message = message
        super().__init__(message)


def get_request_id(request: Request) -> str:
    """Canonical accessor for the per-request identifier set in middleware."""
    return getattr(request.state, "request_id", "unknown")


def error_response(*, status_code: int, code: str, message: str, request_id: str) -> JSONResponse:
    envelope = ErrorEnvelope(error=ErrorBody(code=code, message=message, request_id=request_id))
    return JSONResponse(status_code=status_code, content=envelope.model_dump())


def api_exception_response(request: Request, exc: APIException) -> JSONResponse:
    return error_response(
        status_code=exc.status_code,
        code=exc.code,
        message=exc.message,
        request_id=get_request_id(request),
    )


_T = TypeVar("_T")


async def call_provider(coro: Callable[[], Awaitable[_T]]) -> _T:
    """Calls a provider coroutine and converts ProviderErrors into APIExceptions.

    Eliminates the identical try/except blocks repeated across AI routers.
    """
    try:
        return await coro()
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
