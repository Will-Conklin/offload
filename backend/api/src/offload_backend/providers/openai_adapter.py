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
        response = await self._execute_with_retry(payload=payload)
        return self._parse_success_response(response)

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

    async def _execute_with_retry(self, *, payload: dict) -> httpx.Response:
        """Execute an OpenAI API request with exponential backoff retry.

        Retries on timeouts, network errors, 429, and 5xx responses.
        Raises the last retryable error after exhausting max attempts.
        """
        url = f"{self._settings.openai_base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self._settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        timeout = httpx.Timeout(self._settings.openai_timeout_seconds)

        total_delay_slept = 0.0
        max_attempts = self._settings.ai_retry_max_attempts
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

    async def _default_request_executor(
        self,
        url: str,
        payload: dict,
        headers: dict,
        timeout: httpx.Timeout,
    ) -> httpx.Response:
        async with httpx.AsyncClient(timeout=timeout) as client:
            return await client.post(url, json=payload, headers=headers)

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

    async def compile_brain_dump(
        self,
        *,
        input_text: str,
        context_hints: list[str],
    ) -> ProviderBrainDumpResult:
        if not self._settings.openai_api_key:
            raise ProviderUnavailable("OpenAI API key is not configured")

        payload = self._brain_dump_request_payload(
            input_text=input_text,
            context_hints=context_hints,
        )
        response = await self._execute_with_retry(payload=payload)
        return self._parse_brain_dump_response(response)

    def _brain_dump_request_payload(
        self,
        *,
        input_text: str,
        context_hints: list[str],
    ) -> dict:
        return {
            "model": self._settings.openai_model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You extract and categorize items from unstructured text. "
                        "Valid type values: task, note, idea, question, "
                        "decision, concern, reference. "
                        "Return strict JSON with this shape: "
                        '{"items":[{"title":"...","type":"..."}]}. '
                        "Produce one item per distinct thought, action, or topic. "
                        "Keep titles concise (under 100 words each)."
                    ),
                },
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "input_text": input_text,
                            "context_hints": context_hints,
                        }
                    ),
                },
            ],
            "response_format": {"type": "json_object"},
        }

    def _parse_brain_dump_response(self, response: httpx.Response) -> ProviderBrainDumpResult:
        try:
            body = response.json()
            content = body["choices"][0]["message"]["content"]
            parsed = json.loads(content)
            items = parsed["items"]
        except (KeyError, IndexError, ValueError, TypeError, json.JSONDecodeError) as exc:
            raise ProviderResponseError("OpenAI brain dump response parsing failed") from exc

        usage = body.get("usage", {})
        input_tokens = int(usage.get("prompt_tokens", 0))
        output_tokens = int(usage.get("completion_tokens", 0))

        if not isinstance(items, list):
            raise ProviderResponseError("OpenAI brain dump response did not return an items array")

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
        if not self._settings.openai_api_key:
            raise ProviderUnavailable("OpenAI API key is not configured")

        payload = self._decision_request_payload(
            input_text=input_text,
            context_hints=context_hints,
            clarifying_answers=clarifying_answers,
        )
        response = await self._execute_with_retry(payload=payload)
        return self._parse_decision_response(response)

    def _decision_request_payload(
        self,
        *,
        input_text: str,
        context_hints: list[str],
        clarifying_answers: list[dict],
    ) -> dict:
        return {
            "model": self._settings.openai_model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You help users overcome decision fatigue by surfacing 2–3 "
                        "good-enough options. Keep descriptions concise (under 2 sentences). "
                        "Mark exactly one option as is_recommended. "
                        "If the input lacks enough context, include 1–2 short clarifying "
                        "questions (max 2). "
                        "Return strict JSON with this shape: "
                        '{"options":[{"title":"...","description":"...","is_recommended":true/false}],'
                        '"clarifying_questions":["..."]}. '
                        "Never use urgency language. All suggestions are optional."
                    ),
                },
                {
                    "role": "user",
                    "content": json.dumps(
                        {
                            "input_text": input_text,
                            "context_hints": context_hints,
                            "clarifying_answers": clarifying_answers,
                        }
                    ),
                },
            ],
            "response_format": {"type": "json_object"},
        }

    def _parse_decision_response(self, response: httpx.Response) -> ProviderDecisionResult:
        try:
            body = response.json()
            content = body["choices"][0]["message"]["content"]
            parsed = json.loads(content)
            options = parsed["options"]
            clarifying_questions = parsed.get("clarifying_questions", [])
        except (KeyError, IndexError, ValueError, TypeError, json.JSONDecodeError) as exc:
            raise ProviderResponseError("OpenAI decision response parsing failed") from exc

        usage = body.get("usage", {})
        input_tokens = int(usage.get("prompt_tokens", 0))
        output_tokens = int(usage.get("completion_tokens", 0))

        if not isinstance(options, list):
            raise ProviderResponseError("OpenAI decision response did not return an options array")
        if not isinstance(clarifying_questions, list):
            clarifying_questions = []

        return ProviderDecisionResult(
            options=options,
            clarifying_questions=clarifying_questions[:2],
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )
