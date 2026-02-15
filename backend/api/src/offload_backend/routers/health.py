from __future__ import annotations

from fastapi import APIRouter, Depends

from offload_backend.config import Settings
from offload_backend.dependencies import get_app_settings
from offload_backend.schemas import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def get_health(settings: Settings = Depends(get_app_settings)) -> HealthResponse:
    return HealthResponse(version=settings.build_version, environment=settings.environment)
