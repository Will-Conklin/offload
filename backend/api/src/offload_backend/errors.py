from __future__ import annotations

from fastapi import Request
from fastapi.responses import JSONResponse

from offload_backend.schemas import ErrorBody, ErrorEnvelope


class APIException(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        self.status_code = status_code
        self.code = code
        self.message = message
        super().__init__(message)


def _request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "unknown")


def error_response(*, status_code: int, code: str, message: str, request_id: str) -> JSONResponse:
    envelope = ErrorEnvelope(error=ErrorBody(code=code, message=message, request_id=request_id))
    return JSONResponse(status_code=status_code, content=envelope.model_dump())


def api_exception_response(request: Request, exc: APIException) -> JSONResponse:
    return error_response(
        status_code=exc.status_code,
        code=exc.code,
        message=exc.message,
        request_id=_request_id(request),
    )
