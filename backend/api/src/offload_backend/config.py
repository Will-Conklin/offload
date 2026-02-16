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
    openai_api_key: str | None = None
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = "gpt-4o-mini"
    openai_timeout_seconds: float = 20.0
    max_input_chars: int = Field(default=4000, ge=1)
    default_feature_quota: int = Field(default=100, ge=0)

    @model_validator(mode="after")
    def validate_session_secret_policy(self) -> Settings:
        secret = self.session_secret.strip()
        if is_production_like_environment(self.environment):
            if not secret:
                raise ValueError(
                    "OFFLOAD_SESSION_SECRET must be explicitly set in production-like environments",
                )
            if not is_strong_session_secret(secret):
                raise ValueError(
                    "OFFLOAD_SESSION_SECRET is too weak for production-like environments",
                )
            self.session_secret = secret
            return self

        if not secret:
            self.session_secret = secrets.token_urlsafe(32)
        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
