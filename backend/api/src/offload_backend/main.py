from __future__ import annotations

import logging
import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError

from offload_backend.config import get_settings
from offload_backend.errors import APIException, api_exception_response, error_response
from offload_backend.routers.breakdown import router as breakdown_router
from offload_backend.routers.health import router as health_router
from offload_backend.routers.sessions import router as sessions_router
from offload_backend.routers.usage import router as usage_router
from offload_backend.usage_store import SQLiteUsageStore

logger = logging.getLogger("offload_backend")


def create_app() -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI):
        yield
        usage_store = getattr(app.state, "usage_store", None)
        if usage_store is not None:
            usage_store.close()

    app = FastAPI(title="Offload Backend API", version="0.1.0", lifespan=lifespan)
    settings = get_settings()
    app.state.usage_store = SQLiteUsageStore(db_path=settings.usage_db_path)

    @app.middleware("http")
    async def request_context_middleware(request: Request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id

        started_at = time.perf_counter()
        response = await call_next(request)
        elapsed_ms = int((time.perf_counter() - started_at) * 1000)

        logger.info(
            "request_complete",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "latency_ms": elapsed_ms,
            },
        )
        response.headers["X-Request-ID"] = request_id
        return response

    @app.exception_handler(APIException)
    async def api_exception_handler(request: Request, exc: APIException):
        return api_exception_response(request, exc)

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return error_response(
            status_code=422,
            code="validation_error",
            message="Request validation failed",
            request_id=getattr(request.state, "request_id", "unknown"),
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.exception(
            "unhandled_exception",
            extra={"request_id": getattr(request.state, "request_id", "unknown")},
        )
        return error_response(
            status_code=500,
            code="internal_error",
            message="Internal server error",
            request_id=getattr(request.state, "request_id", "unknown"),
        )

    app.include_router(health_router, prefix="/v1")
    app.include_router(sessions_router, prefix="/v1")
    app.include_router(breakdown_router, prefix="/v1")
    app.include_router(usage_router, prefix="/v1")

    return app


app = create_app()
