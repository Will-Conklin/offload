from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config: SettingsConfigDict = SettingsConfigDict(
        env_prefix="OFFLOAD_",
        extra="ignore",
    )

    environment: str = "development"
    build_version: str = "dev"
    session_secret: str = "dev-secret-change-me"
    session_ttl_seconds: int = 3600
    openai_api_key: str | None = None
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = "gpt-4o-mini"
    openai_timeout_seconds: float = 20.0
    max_input_chars: int = Field(default=4000, ge=1)
    default_feature_quota: int = Field(default=100, ge=0)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
