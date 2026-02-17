from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends

from offload_backend.config import Settings
from offload_backend.dependencies import get_app_settings, get_session_claims, get_usage_store
from offload_backend.errors import APIException
from offload_backend.schemas import UsageReconcileRequest, UsageReconcileResponse
from offload_backend.security import SessionClaims
from offload_backend.usage_store import UsageStore

router = APIRouter()


@router.post("/usage/reconcile", response_model=UsageReconcileResponse)
def reconcile_usage(
    request: UsageReconcileRequest,
    claims: SessionClaims = Depends(get_session_claims),
    usage_store: UsageStore = Depends(get_usage_store),
    settings: Settings = Depends(get_app_settings),
) -> UsageReconcileResponse:
    if claims.install_id != request.install_id:
        raise APIException(
            status_code=403,
            code="install_id_mismatch",
            message="Session install_id does not match request install_id",
        )

    server_count = usage_store.reconcile(
        install_id=request.install_id,
        feature=request.feature,
        local_count=request.local_count,
    )
    effective_remaining = max(0, settings.default_feature_quota - server_count)

    return UsageReconcileResponse(
        server_count=server_count,
        effective_remaining=effective_remaining,
        reconciled_at=datetime.now(UTC),
    )
