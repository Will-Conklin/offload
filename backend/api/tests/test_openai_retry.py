from __future__ import annotations

import asyncio

import httpx
import pytest

from offload_backend.config import Settings
from offload_backend.providers.base import ProviderRequestError
from offload_backend.providers.openai_adapter import OpenAIProviderAdapter


def _response(status_code: int, payload: dict) -> httpx.Response:
    request = httpx.Request("POST", "https://api.openai.com/v1/chat/completions")
    return httpx.Response(status_code=status_code, json=payload, request=request)


def _settings(
    *,
    openai_retry_max_attempts: int = 3,
    openai_retry_base_delay_seconds: float = 0.5,
    openai_retry_max_delay_seconds: float = 2.0,
    openai_retry_max_total_delay_seconds: float = 3.0,
    openai_retry_jitter_factor: float = 0.0,
) -> Settings:
    return Settings(
        session_secret="test-secret",
        openai_api_key="test-key",
        openai_retry_max_attempts=openai_retry_max_attempts,
        openai_retry_base_delay_seconds=openai_retry_base_delay_seconds,
        openai_retry_max_delay_seconds=openai_retry_max_delay_seconds,
        openai_retry_max_total_delay_seconds=openai_retry_max_total_delay_seconds,
        openai_retry_jitter_factor=openai_retry_jitter_factor,
    )


def test_openai_adapter_retries_timeout_then_succeeds():
    attempts = {"count": 0}
    slept: list[float] = []

    async def fake_sleep(delay: float):
        slept.append(delay)

    async def fake_executor(url, payload, headers, timeout):
        _ = (url, payload, headers, timeout)
        attempts["count"] += 1
        if attempts["count"] == 1:
            raise httpx.ReadTimeout("timed out")
        return _response(
            200,
            {
                "choices": [
                    {
                        "message": {
                            "content": '{"steps":[{"title":"Step 1","substeps":[]}]}',
                        },
                    }
                ],
                "usage": {"prompt_tokens": 11, "completion_tokens": 7},
            },
        )

    adapter = OpenAIProviderAdapter(
        settings=_settings(),
        request_executor=fake_executor,
        sleep_fn=fake_sleep,
    )

    result = asyncio.run(
        adapter.generate_breakdown(
            input_text="clean kitchen",
            granularity=2,
            context_hints=[],
            template_ids=[],
        ),
    )

    assert attempts["count"] == 2
    assert len(slept) == 1
    assert result.input_tokens == 11
    assert result.output_tokens == 7


def test_openai_adapter_does_not_retry_non_retriable_4xx():
    attempts = {"count": 0}
    slept: list[float] = []

    async def fake_sleep(delay: float):
        slept.append(delay)

    async def fake_executor(url, payload, headers, timeout):
        _ = (url, payload, headers, timeout)
        attempts["count"] += 1
        return _response(400, {"error": {"message": "bad request"}})

    adapter = OpenAIProviderAdapter(
        settings=_settings(),
        request_executor=fake_executor,
        sleep_fn=fake_sleep,
    )

    with pytest.raises(ProviderRequestError, match="rejected"):
        asyncio.run(
            adapter.generate_breakdown(
                input_text="clean kitchen",
                granularity=2,
                context_hints=[],
                template_ids=[],
            ),
        )

    assert attempts["count"] == 1
    assert slept == []


def test_openai_adapter_retries_429_and_5xx_with_bounded_attempts(caplog):
    attempts = {"count": 0}
    slept: list[float] = []

    async def fake_sleep(delay: float):
        slept.append(delay)

    async def fake_executor(url, payload, headers, timeout):
        _ = (url, payload, headers, timeout)
        attempts["count"] += 1
        if attempts["count"] == 1:
            return _response(429, {"error": {"message": "rate limited"}})
        return _response(503, {"error": {"message": "unavailable"}})

    adapter = OpenAIProviderAdapter(
        settings=_settings(openai_retry_max_attempts=3),
        request_executor=fake_executor,
        sleep_fn=fake_sleep,
    )

    with caplog.at_level("WARNING", logger="offload_backend"):
        with pytest.raises(ProviderRequestError, match="server error"):
            asyncio.run(
                adapter.generate_breakdown(
                    input_text="clean kitchen",
                    granularity=2,
                    context_hints=[],
                    template_ids=[],
                ),
            )

    assert attempts["count"] == 3
    assert len(slept) == 2
    terminal = [record for record in caplog.records if record.msg == "provider_retry_terminal"]
    assert terminal
    assert terminal[-1].attempt_count == 3
    assert terminal[-1].error_class == "ProviderRequestError"


def test_openai_adapter_bounds_total_retry_delay_budget():
    attempts = {"count": 0}
    slept: list[float] = []

    async def fake_sleep(delay: float):
        slept.append(delay)

    async def fake_executor(url, payload, headers, timeout):
        _ = (url, payload, headers, timeout)
        attempts["count"] += 1
        return _response(503, {"error": {"message": "unavailable"}})

    adapter = OpenAIProviderAdapter(
        settings=_settings(
            openai_retry_max_attempts=5,
            openai_retry_base_delay_seconds=1.0,
            openai_retry_max_delay_seconds=10.0,
            openai_retry_max_total_delay_seconds=1.5,
        ),
        request_executor=fake_executor,
        sleep_fn=fake_sleep,
    )

    with pytest.raises(ProviderRequestError):
        asyncio.run(
            adapter.generate_breakdown(
                input_text="clean kitchen",
                granularity=2,
                context_hints=[],
                template_ids=[],
            ),
        )

    assert attempts["count"] == 5
    assert sum(slept) <= 1.5
