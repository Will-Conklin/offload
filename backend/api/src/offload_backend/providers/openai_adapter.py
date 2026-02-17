from __future__ import annotations

import asyncio
import json
import logging
import random
from collections.abc import Awaitable, Callable

import httpx

from offload_backend.config import Settings
from offload_backend.providers.base import (
    ProviderBreakdownResult,
    ProviderRequestError,
    ProviderResponseError,
    ProviderTimeout,
    ProviderUnavailable,
)

logger = logging.getLogger("offload_backend")
RequestExecutor = Callable[[str, dict, dict, httpx.Timeout], Awaitable[httpx.Response]]
SleepFunction = Callable[[float], Awaitable[None]]


class OpenAIProviderAdapter:
    provider_name = "openai"

    def __init__(
        self,
        settings: Settings,
        *,
        request_executor: RequestExecutor | None = None,
        sleep_fn: SleepFunction = asyncio.sleep,
        random_fn: Callable[[], float] = random.random,
    ):
        self._settings = settings
        self._request_executor = request_executor or self._default_request_executor
        self._sleep_fn = sleep_fn
        self._random_fn = random_fn

    async def generate_breakdown(
        self,
        *,
        input_text: str,
        granularity: int,
        context_hints: list[str],
        template_ids: list[str],
    ) -> ProviderBreakdownResult:
        if not self._settings.openai_api_key:
            raise ProviderUnavailable("OpenAI API key is not configured")

        payload = self._request_payload(
            input_text=input_text,
            granularity=granularity,
            context_hints=context_hints,
            template_ids=template_ids,
        )
        headers = {
            "Authorization": f"Bearer {self._settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        url = f"{self._settings.openai_base_url}/chat/completions"
        timeout = httpx.Timeout(self._settings.openai_timeout_seconds)

        total_delay_slept = 0.0
        max_attempts = self._settings.openai_retry_max_attempts
        last_retryable_error: Exception | None = None

        for attempt in range(1, max_attempts + 1):
            try:
                response = await self._request_executor(url, payload, headers, timeout)
            except httpx.TimeoutException:
                last_retryable_error = ProviderTimeout("OpenAI request timed out")
            except httpx.HTTPError:
                last_retryable_error = ProviderRequestError("OpenAI request failed")
            else:
                if response.status_code >= 500:
                    last_retryable_error = ProviderRequestError("OpenAI server error")
                elif response.status_code == 429:
                    last_retryable_error = ProviderRequestError("OpenAI rate limited")
                elif response.status_code >= 400:
                    raise ProviderRequestError("OpenAI request rejected")
                else:
                    result = self._parse_success_response(response)
                    if attempt > 1:
                        logger.info(
                            "provider_retry_recovered",
                            extra={"attempt_count": attempt, "provider": self.provider_name},
                        )
                    return result

            assert last_retryable_error is not None
            if attempt >= max_attempts:
                break
            delay = self._retry_delay(attempt=attempt, total_delay_slept=total_delay_slept)
            total_delay_slept += delay
            if delay > 0:
                await self._sleep_fn(delay)

        assert last_retryable_error is not None
        logger.warning(
            "provider_retry_terminal",
            extra={
                "attempt_count": max_attempts,
                "error_class": last_retryable_error.__class__.__name__,
                "provider": self.provider_name,
            },
        )
        raise last_retryable_error

    def _request_payload(
        self,
        *,
        input_text: str,
        granularity: int,
        context_hints: list[str],
        template_ids: list[str],
    ) -> dict:
        return {
            "model": self._settings.openai_model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You generate structured task breakdowns. "
                        "Return strict JSON with this shape: "
                        '{"steps":[{"title":"...","substeps":[...]}]}.'
                    ),
                },
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "input_text": input_text,
                            "granularity": granularity,
                            "context_hints": context_hints,
                            "template_ids": template_ids,
                        }
                    ),
                },
            ],
            "response_format": {"type": "json_object"},
        }

    async def _default_request_executor(
        self,
        url: str,
        payload: dict,
        headers: dict,
        timeout: httpx.Timeout,
    ) -> httpx.Response:
        async with httpx.AsyncClient(timeout=timeout) as client:
            return await client.post(url, json=payload, headers=headers)

    def _retry_delay(self, *, attempt: int, total_delay_slept: float) -> float:
        base = self._settings.openai_retry_base_delay_seconds
        max_delay = self._settings.openai_retry_max_delay_seconds
        bounded_base = min(max_delay, base * (2 ** (attempt - 1)))
        jitter = bounded_base * self._settings.openai_retry_jitter_factor * self._random_fn()
        candidate = min(max_delay, bounded_base + jitter)
        budget_left = max(
            0.0,
            self._settings.openai_retry_max_total_delay_seconds - total_delay_slept,
        )
        return min(candidate, budget_left)

    def _parse_success_response(self, response: httpx.Response) -> ProviderBreakdownResult:
        try:
            body = response.json()
            content = body["choices"][0]["message"]["content"]
            parsed = json.loads(content)
            steps = parsed["steps"]
        except (KeyError, IndexError, ValueError, TypeError, json.JSONDecodeError) as exc:
            raise ProviderResponseError("OpenAI response parsing failed") from exc

        usage = body.get("usage", {})
        input_tokens = int(usage.get("prompt_tokens", 0))
        output_tokens = int(usage.get("completion_tokens", 0))

        if not isinstance(steps, list):
            raise ProviderResponseError("OpenAI response did not return a steps array")

        return ProviderBreakdownResult(
            steps=steps,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )
