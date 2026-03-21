from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Protocol

import httpx
from pydantic import BaseModel, ConfigDict, Field

RequestExecutor = Callable[[str, dict, dict, httpx.Timeout], Awaitable[httpx.Response]]
SleepFunction = Callable[[float], Awaitable[None]]


def compute_retry_delay(
    *,
    attempt: int,
    total_delay_slept: float,
    base_delay: float,
    max_delay: float,
    max_total_delay: float,
    jitter_factor: float,
    random_fn: Callable[[], float],
) -> float:
    bounded_base = min(max_delay, base_delay * (2 ** (attempt - 1)))
    jitter = bounded_base * jitter_factor * random_fn()
    candidate = min(max_delay, bounded_base + jitter)
    budget_left = max(0.0, max_total_delay - total_delay_slept)
    return min(candidate, budget_left)


class ProviderError(Exception):
    pass


class ProviderTimeout(ProviderError):
    pass


class ProviderUnavailable(ProviderError):
    pass


class ProviderRequestError(ProviderError):
    pass


class ProviderResponseError(ProviderError):
    pass


class ProviderBreakdownResult(BaseModel):
    model_config = ConfigDict(frozen=True)

    steps: list[dict] = Field(default_factory=list)
    input_tokens: int
    output_tokens: int


class ProviderBrainDumpResult(BaseModel):
    model_config = ConfigDict(frozen=True)

    items: list[dict] = Field(default_factory=list)
    input_tokens: int
    output_tokens: int


class ProviderDecisionResult(BaseModel):
    model_config = ConfigDict(frozen=True)

    options: list[dict] = Field(default_factory=list)
    clarifying_questions: list[str] = Field(default_factory=list)
    input_tokens: int
    output_tokens: int


class AIProvider(Protocol):
    provider_name: str

    async def generate_breakdown(
        self,
        *,
        input_text: str,
        granularity: int,
        context_hints: list[str],
        template_ids: list[str],
    ) -> ProviderBreakdownResult: ...

    async def compile_brain_dump(
        self,
        *,
        input_text: str,
        context_hints: list[str],
    ) -> ProviderBrainDumpResult: ...

    async def suggest_decisions(
        self,
        *,
        input_text: str,
        context_hints: list[str],
        clarifying_answers: list[dict],
    ) -> ProviderDecisionResult: ...
