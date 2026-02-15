from __future__ import annotations

import json

import httpx

from offload_backend.config import Settings
from offload_backend.providers.base import (
    ProviderBreakdownResult,
    ProviderRequestError,
    ProviderResponseError,
    ProviderTimeout,
    ProviderUnavailable,
)


class OpenAIProviderAdapter:
    provider_name = "openai"

    def __init__(self, settings: Settings):
        self._settings = settings

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

        payload = {
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

        headers = {
            "Authorization": f"Bearer {self._settings.openai_api_key}",
            "Content-Type": "application/json",
        }

        timeout = httpx.Timeout(self._settings.openai_timeout_seconds)

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(
                    f"{self._settings.openai_base_url}/chat/completions",
                    json=payload,
                    headers=headers,
                )
        except httpx.TimeoutException as exc:
            raise ProviderTimeout("OpenAI request timed out") from exc
        except httpx.HTTPError as exc:
            raise ProviderRequestError("OpenAI request failed") from exc

        if response.status_code >= 500:
            raise ProviderRequestError("OpenAI server error")
        if response.status_code >= 400:
            raise ProviderRequestError("OpenAI request rejected")

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
