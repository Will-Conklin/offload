from __future__ import annotations

from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = "ok"
    service: str = "offload-backend-api"
    version: str
    environment: str


class AnonymousSessionRequest(BaseModel):
    install_id: str = Field(min_length=8, max_length=128)
    app_version: str = Field(min_length=1, max_length=32)
    platform: str = Field(min_length=1, max_length=32)


class AnonymousSessionResponse(BaseModel):
    session_token: str
    expires_at: datetime


class BreakdownGenerateRequest(BaseModel):
    input_text: str = Field(min_length=1)
    granularity: int = Field(ge=1, le=5)
    context_hints: list[Annotated[str, Field(min_length=1, max_length=280)]] = Field(
        default_factory=list,
        max_length=32,
    )
    template_ids: list[Annotated[str, Field(min_length=1, max_length=128)]] = Field(
        default_factory=list,
        max_length=32,
    )


class BreakdownStep(BaseModel):
    title: str = Field(min_length=1, max_length=280)
    substeps: list[BreakdownStep] = Field(default_factory=list)


BreakdownStep.model_rebuild()


class BreakdownUsage(BaseModel):
    input_tokens: int = Field(ge=0)
    output_tokens: int = Field(ge=0)


class BreakdownGenerateResponse(BaseModel):
    steps: list[BreakdownStep]
    provider: str
    latency_ms: int = Field(ge=0)
    usage: BreakdownUsage


class UsageReconcileRequest(BaseModel):
    install_id: str = Field(min_length=8, max_length=128)
    feature: str = Field(min_length=1, max_length=64)
    local_count: int = Field(ge=0)
    since: datetime | None = None


class UsageReconcileResponse(BaseModel):
    server_count: int = Field(ge=0)
    effective_remaining: int = Field(ge=0)
    reconciled_at: datetime


class ErrorBody(BaseModel):
    code: str
    message: str
    request_id: str


class ErrorEnvelope(BaseModel):
    error: ErrorBody
