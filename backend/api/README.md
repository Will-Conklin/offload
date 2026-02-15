# Offload Backend API

Backend API package for Offload MVP services.

## Local checks

```bash
python3 -m pip install -e 'backend/api[dev]'
python3 -m ruff check backend/api/src backend/api/tests
python3 -m ty check backend/api/src backend/api/tests
python3 -m pytest backend/api/tests -q
```
