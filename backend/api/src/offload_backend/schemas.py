from __future__ import annotations

from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, model_validator


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
    model_config = ConfigDict(extra="forbid")

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


_BREAKDOWN_MAX_DEPTH = 3


class BreakdownStep(BaseModel):
    title: str = Field(min_length=1, max_length=280)
    substeps: list[BreakdownStep] = Field(default_factory=list, max_length=20)

    @model_validator(mode="after")
    def _enforce_max_depth(self) -> BreakdownStep:
        _check_substep_depth(self.substeps, current_depth=1, max_depth=_BREAKDOWN_MAX_DEPTH)
        return self


def _check_substep_depth(
    substeps: list[BreakdownStep], *, current_depth: int, max_depth: int
) -> None:
    if current_depth > max_depth:
        raise ValueError(f"BreakdownStep nesting exceeds maximum depth of {max_depth}")
    for step in substeps:
        _check_substep_depth(step.substeps, current_depth=current_depth + 1, max_depth=max_depth)


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


class AppleAuthRequest(BaseModel):
    apple_identity_token: str = Field(min_length=1)
    install_id: str = Field(min_length=8, max_length=128)
    display_name: str | None = Field(default=None, max_length=128)


class AppleAuthResponse(BaseModel):
    session_token: str
    expires_at: datetime
    user_id: str


class ErrorBody(BaseModel):
    code: str
    message: str
    request_id: str


class ErrorEnvelope(BaseModel):
    error: ErrorBody


class BrainDumpCompileRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    input_text: str = Field(min_length=1)
    context_hints: list[Annotated[str, Field(min_length=1, max_length=280)]] = Field(
        default_factory=list,
        max_length=32,
    )


class BrainDumpItem(BaseModel):
    title: str = Field(min_length=1, max_length=280)
    type: str = Field(min_length=1, max_length=32)


class BrainDumpUsage(BaseModel):
    input_tokens: int = Field(ge=0)
    output_tokens: int = Field(ge=0)


class BrainDumpCompileResponse(BaseModel):
    items: list[BrainDumpItem]
    provider: str
    latency_ms: int = Field(ge=0)
    usage: BrainDumpUsage


class DecisionClarifyingAnswer(BaseModel):
    question: str = Field(min_length=1, max_length=280)
    answer: str = Field(min_length=1, max_length=280)


class DecisionRecommendRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    input_text: str = Field(min_length=1)
    context_hints: list[Annotated[str, Field(min_length=1, max_length=280)]] = Field(
        default_factory=list,
        max_length=32,
    )
    clarifying_answers: list[DecisionClarifyingAnswer] = Field(
        default_factory=list,
        max_length=2,
    )


class DecisionOption(BaseModel):
    title: str = Field(min_length=1, max_length=280)
    description: str = Field(min_length=1, max_length=560)
    is_recommended: bool = False


class DecisionUsage(BaseModel):
    input_tokens: int = Field(ge=0)
    output_tokens: int = Field(ge=0)


class DecisionRecommendResponse(BaseModel):
    options: list[DecisionOption]
    clarifying_questions: list[Annotated[str, Field(min_length=1, max_length=280)]] = Field(
        default_factory=list,
        max_length=2,
    )
    provider: str
    latency_ms: int = Field(ge=0)
    usage: DecisionUsage


class ExecFunctionPromptRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    input_text: str = Field(min_length=1)
    context_hints: list[Annotated[str, Field(min_length=1, max_length=280)]] = Field(
        default_factory=list,
        max_length=32,
    )
    strategy_history: list[ExecFunctionStrategyFeedback] = Field(
        default_factory=list,
        max_length=50,
    )


class ExecFunctionStrategyFeedback(BaseModel):
    """Historical feedback for a strategy the user has tried before."""

    challenge_type: str = Field(min_length=1, max_length=32)
    strategy_id: str = Field(min_length=1, max_length=64)
    thumbs_up: bool
    led_to_completion: bool


class ExecFunctionStrategy(BaseModel):
    """A micro-strategy suggested for an executive function challenge."""

    strategy_id: str = Field(min_length=1, max_length=64)
    challenge_type: str = Field(min_length=1, max_length=32)
    title: str = Field(min_length=1, max_length=280)
    description: str = Field(min_length=1, max_length=560)
    action_prompt: str = Field(min_length=1, max_length=560)


class ExecFunctionUsage(BaseModel):
    input_tokens: int = Field(ge=0)
    output_tokens: int = Field(ge=0)


class ExecFunctionPromptResponse(BaseModel):
    detected_challenge: str = Field(min_length=1, max_length=32)
    strategies: list[ExecFunctionStrategy] = Field(max_length=3)
    encouragement: str = Field(min_length=1, max_length=280)
    provider: str
    latency_ms: int = Field(ge=0)
    usage: ExecFunctionUsage
