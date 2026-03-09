from __future__ import annotations

import asyncio
import json
import os

import httpx
import pytest

from offload_backend.config import Settings, get_settings
from offload_backend.dependencies import get_provider
from offload_backend.providers.anthropic_adapter import AnthropicProviderAdapter
from offload_backend.providers.base import (
    ProviderRequestError,
    ProviderResponseError,
    ProviderUnavailable,
)


def _response(status_code: int, payload: dict) -> httpx.Response:
    request = httpx.Request("POST", "https://api.anthropic.com/v1/messages")
    return httpx.Response(status_code=status_code, json=payload, request=request)


def _breakdown_response() -> httpx.Response:
    text = json.dumps({"steps": [{"title": "Step 1", "substeps": []}]})
    return _response(
        200,
        {
            "content": [{"type": "text", "text": text}],
            "usage": {"input_tokens": 10, "output_tokens": 20},
        },
    )


def _brain_dump_response() -> httpx.Response:
    text = json.dumps({"items": [{"title": "Call dentist", "type": "task"}]})
    return _response(
        200,
        {
            "content": [{"type": "text", "text": text}],
            "usage": {"input_tokens": 15, "output_tokens": 25},
        },
    )


def _settings(**overrides) -> Settings:
    defaults = {
        "session_secret": "test-secret",
        "anthropic_api_key": "test-anthropic-key",
        "ai_retry_max_attempts": 3,
        "ai_retry_base_delay_seconds": 0.5,
        "ai_retry_max_delay_seconds": 2.0,
        "ai_retry_max_total_delay_seconds": 3.0,
        "ai_retry_jitter_factor": 0.0,
    }
    return Settings(**(defaults | overrides))


def _adapter(executor, settings=None) -> tuple[AnthropicProviderAdapter, list[float]]:
    slept: list[float] = []

    async def fake_sleep(delay: float):
        slept.append(delay)

    adapter = AnthropicProviderAdapter(
        settings=settings or _settings(),
        request_executor=executor,
        sleep_fn=fake_sleep,
    )
    return adapter, slept


# --- generate_breakdown ---

def test_anthropic_generate_breakdown_success():
    async def executor(url, payload, headers, timeout):
        assert "anthropic-version" in headers
        assert headers["x-api-key"] == "test-anthropic-key"
        assert "/v1/messages" in url
        return _breakdown_response()

    adapter, _ = _adapter(executor)
    result = asyncio.run(
        adapter.generate_breakdown(
            input_text="clean the kitchen",
            granularity=2,
            context_hints=[],
            template_ids=[],
        )
    )

    assert result.input_tokens == 10
    assert result.output_tokens == 20
    assert isinstance(result.steps, list)


def test_anthropic_generate_breakdown_raises_on_missing_key():
    adapter = AnthropicProviderAdapter(settings=_settings(anthropic_api_key=None))
    with pytest.raises(ProviderUnavailable, match="API key"):
        asyncio.run(
            adapter.generate_breakdown(
                input_text="test", granularity=1, context_hints=[], template_ids=[]
            )
        )


def test_anthropic_generate_breakdown_raises_on_parse_error():
    async def executor(url, payload, headers, timeout):
        return _response(200, {"content": [{"type": "text", "text": "not json"}], "usage": {}})

    adapter, _ = _adapter(executor)
    with pytest.raises(ProviderResponseError):
        asyncio.run(
            adapter.generate_breakdown(
                input_text="test", granularity=1, context_hints=[], template_ids=[]
            )
        )


# --- compile_brain_dump ---

def test_anthropic_compile_brain_dump_success():
    async def executor(url, payload, headers, timeout):
        return _brain_dump_response()

    adapter, _ = _adapter(executor)
    result = asyncio.run(
        adapter.compile_brain_dump(input_text="I need to call the dentist", context_hints=[])
    )

    assert result.input_tokens == 15
    assert result.output_tokens == 25
    assert isinstance(result.items, list)


def test_anthropic_compile_brain_dump_raises_on_missing_key():
    adapter = AnthropicProviderAdapter(settings=_settings(anthropic_api_key=None))
    with pytest.raises(ProviderUnavailable, match="API key"):
        asyncio.run(adapter.compile_brain_dump(input_text="test", context_hints=[]))


# --- retry behaviour ---

def test_anthropic_retries_timeout_then_succeeds():
    attempts = {"count": 0}

    async def executor(url, payload, headers, timeout):
        attempts["count"] += 1
        if attempts["count"] == 1:
            raise httpx.ReadTimeout("timed out")
        return _breakdown_response()

    adapter, slept = _adapter(executor)
    result = asyncio.run(
        adapter.generate_breakdown(
            input_text="test", granularity=1, context_hints=[], template_ids=[]
        )
    )

    assert attempts["count"] == 2
    assert len(slept) == 1
    assert result.input_tokens == 10


def test_anthropic_does_not_retry_non_retryable_4xx():
    attempts = {"count": 0}

    async def executor(url, payload, headers, timeout):
        attempts["count"] += 1
        return _response(400, {"type": "error", "error": {"type": "invalid_request_error"}})

    adapter, slept = _adapter(executor)
    with pytest.raises(ProviderRequestError, match="rejected"):
        asyncio.run(
            adapter.generate_breakdown(
                input_text="test", granularity=1, context_hints=[], template_ids=[]
            )
        )

    assert attempts["count"] == 1
    assert slept == []


def test_anthropic_retries_429_and_5xx_up_to_max_attempts(caplog):
    attempts = {"count": 0}

    async def executor(url, payload, headers, timeout):
        attempts["count"] += 1
        if attempts["count"] == 1:
            return _response(429, {"error": "rate limited"})
        return _response(503, {"error": "unavailable"})

    adapter, slept = _adapter(executor)
    with caplog.at_level("WARNING", logger="offload_backend"):
        with pytest.raises(ProviderUnavailable):
            asyncio.run(
                adapter.generate_breakdown(
                    input_text="test", granularity=1, context_hints=[], template_ids=[]
                )
            )

    assert attempts["count"] == 3
    assert len(slept) == 2
    terminal = [r for r in caplog.records if r.msg == "provider_retry_terminal"]
    assert terminal
    assert terminal[-1].provider == "anthropic"


def test_anthropic_retries_529_overloaded():
    attempts = {"count": 0}

    async def executor(url, payload, headers, timeout):
        attempts["count"] += 1
        if attempts["count"] < 3:
            return _response(529, {"error": "overloaded"})
        return _brain_dump_response()

    adapter, _ = _adapter(executor)
    result = asyncio.run(
        adapter.compile_brain_dump(input_text="brain dump text", context_hints=[])
    )

    assert attempts["count"] == 3
    assert result.items


def test_anthropic_get_provider_dependency_returns_anthropic(app):
    """Confirm get_provider returns AnthropicProviderAdapter when ai_provider=anthropic."""
    get_settings.cache_clear()
    os.environ["OFFLOAD_AI_PROVIDER"] = "anthropic"
    os.environ["OFFLOAD_ANTHROPIC_API_KEY"] = "sk-ant-test"
    try:
        get_settings.cache_clear()
        settings = get_settings()
        provider = get_provider(settings=settings)
        assert isinstance(provider, AnthropicProviderAdapter)
    finally:
        del os.environ["OFFLOAD_AI_PROVIDER"]
        del os.environ["OFFLOAD_ANTHROPIC_API_KEY"]
        get_settings.cache_clear()
