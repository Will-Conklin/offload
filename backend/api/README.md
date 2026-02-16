# Offload Backend API

Backend API package for Offload MVP services.

## Session secret policy

- Development/test: if `OFFLOAD_SESSION_SECRET` is unset, the backend generates
  a random in-memory secret at startup.
- Production-like environments (`OFFLOAD_ENVIRONMENT` not in
  `dev/development/local/test/testing`): `OFFLOAD_SESSION_SECRET` is required
  and must be strong.
- Session token v2 settings:
  - `OFFLOAD_SESSION_TOKEN_ISSUER` (default: `offload-backend`)
  - `OFFLOAD_SESSION_TOKEN_AUDIENCE` (default: `offload-ios`)
  - `OFFLOAD_SESSION_TOKEN_ACTIVE_KID` (default: `v2-default`)
  - optional `OFFLOAD_SESSION_SIGNING_KEYS` as JSON map for key rotation
    (for example: `{"v2-default":"<secret>"}`); if omitted, active key uses
    `OFFLOAD_SESSION_SECRET`.

Example:

```bash
OFFLOAD_ENVIRONMENT=production
OFFLOAD_SESSION_SECRET='replace-with-a-strong-secret-value'
```

## Local checks

```bash
python3 -m pip install -e 'backend/api[dev]'
python3 -m ruff check backend/api/src backend/api/tests
python3 -m ty check backend/api/src backend/api/tests
python3 -m pytest backend/api/tests -q
python3 -m pytest backend/api/tests -q --cov=offload_backend --cov-report=term-missing:skip-covered
```
