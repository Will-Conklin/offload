# Purpose: Anthropic Claude provider adapter implementing the AIProvider protocol.
# Authority: Code-level
# Governed by: CLAUDE.md

from __future__ import annotations

import asyncio
import json
import logging
import random
from collections.abc import Callable

import httpx

from offload_backend.config import Settings
from offload_backend.providers.base import (
    ProviderBrainDumpResult,
    ProviderBreakdownResult,
    ProviderDecisionResult,
    ProviderRequestError,
    ProviderResponseError,
    ProviderTimeout,
    ProviderUnavailable,
    RequestExecutor,
    SleepFunction,
    compute_retry_delay,
)

logger = logging.getLogger("offload_backend")

_FENCE_PREFIXES = ("```json", "```")


def _strip_code_fences(text: str) -> str:
    """Strip markdown code fences from a string before JSON parsing."""
    stripped = text.strip()
    for prefix in _FENCE_PREFIXES:
        if stripped.startswith(prefix):
            stripped = stripped[len(prefix):]
            if stripped.endswith("```"):
                stripped = stripped[:-3]
            return stripped.strip()
    return stripped


class AnthropicProviderAdapter:
    """Anthropic Claude adapter for breakdown and brain dump generation.

    Uses the Anthropic Messages API with exponential backoff retry on
    transient failures (5xx, 429, network errors). Raises provider-neutral
    exceptions so routers remain backend-agnostic.
    """

    provider_name = "anthropic"

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
        """Generate a structured task breakdown using Claude.

        Returns a ProviderBreakdownResult with steps and token usage.
        Raises ProviderUnavailable if the API key is not configured.
        """
        if not self._settings.anthropic_api_key:
            raise ProviderUnavailable("Anthropic API key is not configured")

        payload = {
            "model": self._settings.anthropic_model,
            "max_tokens": 2048,
            "system": (
                "You generate structured task breakdowns. "
                "Return strict JSON with this shape: "
                '{"steps":[{"title":"...","substeps":[{"title":"...","substeps":[]}]}]}. '
                "Each substep is an object with a title string and an empty substeps array. "
                "Output only the JSON object, no markdown formatting, no other text."
            ),
            "messages": [
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
                }
            ],
        }
        response = await self._execute_with_retry(payload=payload)
        return self._parse_breakdown_response(response)

    async def compile_brain_dump(
        self,
        *,
        input_text: str,
        context_hints: list[str],
    ) -> ProviderBrainDumpResult:
        """Extract and categorize items from unstructured text using Claude.

        Returns a ProviderBrainDumpResult with items and token usage.
        Raises ProviderUnavailable if the API key is not configured.
        """
        if not self._settings.anthropic_api_key:
            raise ProviderUnavailable("Anthropic API key is not configured")

        payload = {
            "model": self._settings.anthropic_model,
            "max_tokens": 2048,
            "system": (
                "You extract and categorize items from unstructured text. "
                "Valid type values: task, note, idea, question, "
                "decision, concern, reference. "
                "Return strict JSON with this shape: "
                '{"items":[{"title":"...","type":"..."}]}. '
                "Produce one item per distinct thought, action, or topic. "
                "Keep titles concise (under 100 words each). "
                "Output only the JSON object, no other text."
            ),
            "messages": [
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "input_text": input_text,
                            "context_hints": context_hints,
                        }
                    ),
                }
            ],
        }
        response = await self._execute_with_retry(payload=payload)
        return self._parse_brain_dump_response(response)

    async def _execute_with_retry(self, *, payload: dict) -> httpx.Response:
        """Execute an Anthropic API request with exponential backoff retry.

        Retries on timeouts, network errors, 429, and 5xx responses.
        Raises the last retryable error after exhausting max attempts.
        """
        url = f"{self._settings.anthropic_base_url}/v1/messages"
        headers = {
            "x-api-key": self._settings.anthropic_api_key or "",
            "anthropic-version": self._settings.anthropic_version,
            "content-type": "application/json",
        }
        timeout = httpx.Timeout(self._settings.anthropic_timeout_seconds)

        total_delay_slept = 0.0
        max_attempts = self._settings.ai_retry_max_attempts
        last_retryable_error: Exception | None = None

        for attempt in range(1, max_attempts + 1):
            try:
                response = await self._request_executor(url, payload, headers, timeout)
            except httpx.TimeoutException:
                last_retryable_error = ProviderTimeout("Anthropic request timed out")
            except httpx.HTTPError:
                last_retryable_error = ProviderRequestError("Anthropic request failed")
            else:
                if response.status_code == 529 or response.status_code >= 500:
                    last_retryable_error = ProviderUnavailable("Anthropic service unavailable")
                elif response.status_code == 429:
                    last_retryable_error = ProviderRequestError("Anthropic rate limited")
                elif response.status_code >= 400:
                    raise ProviderRequestError("Anthropic request rejected")
                else:
                    if attempt > 1:
                        logger.info(
                            "provider_retry_recovered",
                            extra={"attempt_count": attempt, "provider": self.provider_name},
                        )
                    return response

            if last_retryable_error is None:
                raise RuntimeError("retry loop invariant violated")
            if attempt >= max_attempts:
                break
            delay = compute_retry_delay(
                attempt=attempt,
                total_delay_slept=total_delay_slept,
                base_delay=self._settings.ai_retry_base_delay_seconds,
                max_delay=self._settings.ai_retry_max_delay_seconds,
                max_total_delay=self._settings.ai_retry_max_total_delay_seconds,
                jitter_factor=self._settings.ai_retry_jitter_factor,
                random_fn=self._random_fn,
            )
            total_delay_slept += delay
            if delay > 0:
                await self._sleep_fn(delay)

        if last_retryable_error is None:
            raise RuntimeError("retry loop invariant violated")
        logger.warning(
            "provider_retry_terminal",
            extra={
                "attempt_count": max_attempts,
                "error_class": last_retryable_error.__class__.__name__,
                "provider": self.provider_name,
            },
        )
        raise last_retryable_error

    def _parse_breakdown_response(self, response: httpx.Response) -> ProviderBreakdownResult:
        try:
            body = response.json()
            content = _strip_code_fences(body["content"][0]["text"])
            parsed = json.loads(content)
            steps = parsed["steps"]
        except (KeyError, IndexError, ValueError, TypeError, json.JSONDecodeError) as exc:
            raise ProviderResponseError("Anthropic breakdown response parsing failed") from exc

        usage = body.get("usage", {})
        input_tokens = int(usage.get("input_tokens", 0))
        output_tokens = int(usage.get("output_tokens", 0))

        if not isinstance(steps, list):
            raise ProviderResponseError("Anthropic response did not return a steps array")

        return ProviderBreakdownResult(
            steps=steps,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )

    def _parse_brain_dump_response(self, response: httpx.Response) -> ProviderBrainDumpResult:
        try:
            body = response.json()
            content = _strip_code_fences(body["content"][0]["text"])
            parsed = json.loads(content)
            items = parsed["items"]
        except (KeyError, IndexError, ValueError, TypeError, json.JSONDecodeError) as exc:
            raise ProviderResponseError("Anthropic brain dump response parsing failed") from exc

        usage = body.get("usage", {})
        input_tokens = int(usage.get("input_tokens", 0))
        output_tokens = int(usage.get("output_tokens", 0))

        if not isinstance(items, list):
            raise ProviderResponseError("Anthropic response did not return an items array")

        return ProviderBrainDumpResult(
            items=items,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )

    async def suggest_decisions(
        self,
        *,
        input_text: str,
        context_hints: list[str],
        clarifying_answers: list[dict],
    ) -> ProviderDecisionResult:
        """Surface 2–3 good-enough options to help the user overcome decision fatigue.

        Returns a ProviderDecisionResult with options, optional clarifying questions,
        and token usage. Raises ProviderUnavailable if the API key is not configured.
        """
        if not self._settings.anthropic_api_key:
            raise ProviderUnavailable("Anthropic API key is not configured")

        payload = {
            "model": self._settings.anthropic_model,
            "max_tokens": 1024,
            "system": (
                "You help users overcome decision fatigue by surfacing 2–3 "
                "good-enough options. Keep descriptions concise (under 2 sentences). "
                "Mark exactly one option as is_recommended. "
                "If the input lacks enough context, include 1–2 short clarifying "
                "questions (max 2). "
                "Return strict JSON with this shape: "
                '{"options":[{"title":"...","description":"...","is_recommended":true/false}],'
                '"clarifying_questions":["..."]}. '
                "Never use urgency language. All suggestions are optional. "
                "Output only the JSON object, no other text."
            ),
            "messages": [
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "input_text": input_text,
                            "context_hints": context_hints,
                            "clarifying_answers": clarifying_answers,
                        }
                    ),
                }
            ],
        }
        response = await self._execute_with_retry(payload=payload)
        return self._parse_decision_response(response)

    def _parse_decision_response(self, response: httpx.Response) -> ProviderDecisionResult:
        try:
            body = response.json()
            content = _strip_code_fences(body["content"][0]["text"])
            parsed = json.loads(content)
            options = parsed["options"]
            clarifying_questions = parsed.get("clarifying_questions", [])
        except (KeyError, IndexError, ValueError, TypeError, json.JSONDecodeError) as exc:
            raise ProviderResponseError("Anthropic decision response parsing failed") from exc

        usage = body.get("usage", {})
        input_tokens = int(usage.get("input_tokens", 0))
        output_tokens = int(usage.get("output_tokens", 0))

        if not isinstance(options, list):
            raise ProviderResponseError("Anthropic response did not return an options array")
        if not isinstance(clarifying_questions, list):
            clarifying_questions = []

        return ProviderDecisionResult(
            options=options,
            clarifying_questions=clarifying_questions[:2],
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )

    async def _default_request_executor(
        self,
        url: str,
        payload: dict,
        headers: dict,
        timeout: httpx.Timeout,
    ) -> httpx.Response:
        async with httpx.AsyncClient(timeout=timeout) as client:
            return await client.post(url, json=payload, headers=headers)
