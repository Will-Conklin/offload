import asyncio
import os
import time

import httpx
import pytest

from offload_backend.dependencies import get_provider
from offload_backend.providers.base import ProviderBreakdownResult

CONCURRENT_REQUESTS = 50
P95_THRESHOLD_MS = 100.0


class FakeProvider:
    """Instant-return provider to isolate FastAPI + auth overhead."""

    async def generate_breakdown(self, *, input_text, granularity, context_hints, template_ids):
        _ = (input_text, granularity, context_hints, template_ids)
        return ProviderBreakdownResult(
            steps=[{"title": "Step 1", "substeps": []}],
            input_tokens=10,
            output_tokens=20,
        )


async def _run_load_test(app) -> list[float]:
    """Fire concurrent requests and return per-request latencies in ms."""
    app.dependency_overrides[get_provider] = lambda: FakeProvider()
    try:
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url='http://test') as ac:
            # Create session token
            session_resp = await ac.post(
                '/v1/sessions/anonymous',
                json={'install_id': 'load-test', 'app_version': '1.0', 'platform': 'ios'},
            )
            assert session_resp.status_code == 200
            token = session_resp.json()['session_token']

            headers = {
                'Authorization': f'Bearer {token}',
                'X-Offload-Cloud-Opt-In': 'true',
            }
            payload = {'input_text': 'Clean the kitchen', 'granularity': 3}

            # Warmup: prime lazy-loaded middleware and connection pools
            warmup_resp = await ac.post(
                '/v1/ai/breakdown/generate',
                json=payload,
                headers=headers,
            )
            assert warmup_resp.status_code == 200

            async def timed_request() -> float:
                start = time.perf_counter()
                resp = await ac.post(
                    '/v1/ai/breakdown/generate',
                    json=payload,
                    headers=headers,
                )
                elapsed_ms = (time.perf_counter() - start) * 1000
                assert resp.status_code == 200
                return elapsed_ms

            latencies = await asyncio.gather(
                *[timed_request() for _ in range(CONCURRENT_REQUESTS)]
            )
    finally:
        app.dependency_overrides.pop(get_provider, None)

    return sorted(latencies)


def _percentile(sorted_values: list[float], pct: float) -> float:
    """Compute percentile from pre-sorted values."""
    idx = int(len(sorted_values) * pct / 100)
    return sorted_values[min(idx, len(sorted_values) - 1)]


@pytest.mark.benchmark
@pytest.mark.skipif(
    bool(os.environ.get('CI')) and not os.environ.get('OFFLOAD_RUN_BENCHMARKS'),
    reason='Skipped in CI unless OFFLOAD_RUN_BENCHMARKS=1',
)
def test_breakdown_p95_latency_under_load(app):
    """Assert p95 latency stays under threshold with 50 concurrent requests."""

    latencies = asyncio.run(_run_load_test(app))

    p50 = _percentile(latencies, 50)
    p95 = _percentile(latencies, 95)
    p99 = _percentile(latencies, 99)

    print(f'\n--- Breakdown Latency ({CONCURRENT_REQUESTS} concurrent) ---')
    print(f'  p50: {p50:.1f}ms')
    print(f'  p95: {p95:.1f}ms')
    print(f'  p99: {p99:.1f}ms')
    print(f'  min: {latencies[0]:.1f}ms')
    print(f'  max: {latencies[-1]:.1f}ms')

    assert p95 < P95_THRESHOLD_MS, (
        f'p95 latency {p95:.1f}ms exceeds threshold {P95_THRESHOLD_MS}ms'
    )
