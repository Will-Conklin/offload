from __future__ import annotations

from typing import Protocol

from pydantic import BaseModel, ConfigDict, Field


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


class AIProvider(Protocol):
    async def generate_breakdown(
        self,
        *,
        input_text: str,
        granularity: int,
        context_hints: list[str],
        template_ids: list[str],
    ) -> ProviderBreakdownResult: ...
