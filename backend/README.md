# Backend

Backend services for Offload.

## Structure

- `api/` - API server
  - `src/` - Source code
  - `tests/` - Tests
- `infra/` - Infrastructure as code (Terraform/Pulumi)

## MVP Scope (Current)

- Python + FastAPI scaffold for backend AI routing.
- Anonymous device session endpoint (`/v1/sessions/anonymous`).
- Smart Task Breakdown endpoint (`/v1/ai/breakdown/generate`) behind an OpenAI adapter.
- Usage reconciliation endpoint (`/v1/usage/reconcile`).
- Privacy default: cloud processing requires explicit opt-in and content is not retained.

## Local Development

```bash
python3 -m pip install -e 'backend/api[dev]'
python3 -m ruff check backend/api/src backend/api/tests
python3 -m ty check backend/api/src backend/api/tests
python3 -m pytest backend/api/tests -q
```

## Run API Locally

```bash
python3 -m uvicorn offload_backend.main:app --app-dir backend/api/src --reload
```

### Environment Variables

- `OFFLOAD_SESSION_SECRET` - HMAC secret for anonymous session tokens.
- `OFFLOAD_SESSION_TTL_SECONDS` - Session TTL in seconds.
- `OFFLOAD_OPENAI_API_KEY` - OpenAI API key (required for cloud generation).
- `OFFLOAD_OPENAI_MODEL` - OpenAI model name.
- `OFFLOAD_MAX_INPUT_CHARS` - Max input size accepted by breakdown endpoint.
- `OFFLOAD_DEFAULT_FEATURE_QUOTA` - Feature usage quota used by reconciliation.
