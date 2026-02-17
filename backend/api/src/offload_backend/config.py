from __future__ import annotations

import secrets
from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from offload_backend.session_security import (
    is_production_like_environment,
    is_strong_session_secret,
)


class Settings(BaseSettings):
    model_config: SettingsConfigDict = SettingsConfigDict(
        env_prefix="OFFLOAD_",
        extra="ignore",
    )

    environment: str = "development"
    build_version: str = "dev"
    session_secret: str = ""
    session_ttl_seconds: int = 3600
    session_token_issuer: str = "offload-backend"
    session_token_audience: str = "offload-ios"
    session_token_active_kid: str = "v2-default"
    session_signing_keys: dict[str, str] = Field(default_factory=dict)
    session_issue_limit_per_ip: int = Field(default=8, ge=1)
    session_issue_limit_per_install: int = Field(default=4, ge=1)
    session_issue_limit_window_seconds: int = Field(default=60, ge=1)
    openai_api_key: str | None = None
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = "gpt-4o-mini"
    openai_timeout_seconds: float = 20.0
    openai_retry_max_attempts: int = Field(default=3, ge=1, le=10)
    openai_retry_base_delay_seconds: float = Field(default=0.25, ge=0.0)
    openai_retry_max_delay_seconds: float = Field(default=2.0, ge=0.0)
    openai_retry_max_total_delay_seconds: float = Field(default=4.0, ge=0.0)
    openai_retry_jitter_factor: float = Field(default=0.25, ge=0.0, le=1.0)
    max_input_chars: int = Field(default=4000, ge=1)
    default_feature_quota: int = Field(default=100, ge=0)
    usage_db_path: str = ".offload-backend/usage.sqlite3"

    @model_validator(mode="after")
    def validate_session_secret_policy(self) -> Settings:
        production_like = is_production_like_environment(self.environment)
        secret = self.session_secret.strip()
        if production_like:
            if not secret:
                raise ValueError(
                    "OFFLOAD_SESSION_SECRET must be explicitly set in production-like environments",
                )
            if not is_strong_session_secret(secret):
                raise ValueError(
                    "OFFLOAD_SESSION_SECRET is too weak for production-like environments",
                )
        elif not secret:
            self.session_secret = secrets.token_urlsafe(32)
        else:
            self.session_secret = secret

        self.session_token_issuer = self.session_token_issuer.strip()
        self.session_token_audience = self.session_token_audience.strip()
        self.session_token_active_kid = self.session_token_active_kid.strip()
        if (
            not self.session_token_issuer
            or not self.session_token_audience
            or not self.session_token_active_kid
        ):
            raise ValueError(
                "Session token issuer, audience, and active key ID must be non-empty",
            )

        normalized_signing_keys: dict[str, str] = {}
        for kid, key in self.session_signing_keys.items():
            normalized_kid = kid.strip()
            normalized_key = key.strip()
            if not normalized_kid or not normalized_key:
                raise ValueError(
                    "OFFLOAD_SESSION_SIGNING_KEYS must use non-empty key IDs and values",
                )
            normalized_signing_keys[normalized_kid] = normalized_key

        if not normalized_signing_keys:
            normalized_signing_keys[self.session_token_active_kid] = self.session_secret
        elif self.session_token_active_kid not in normalized_signing_keys:
            raise ValueError(
                "OFFLOAD_SESSION_TOKEN_ACTIVE_KID must exist in OFFLOAD_SESSION_SIGNING_KEYS",
            )

        if production_like:
            for key in normalized_signing_keys.values():
                if not is_strong_session_secret(key):
                    raise ValueError(
                        (
                            "OFFLOAD_SESSION_SIGNING_KEYS values must be strong in "
                            "production-like environments"
                        ),
                    )

        self.session_signing_keys = normalized_signing_keys
        self.usage_db_path = self.usage_db_path.strip()
        if not self.usage_db_path:
            raise ValueError("OFFLOAD_USAGE_DB_PATH must be non-empty")
        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
