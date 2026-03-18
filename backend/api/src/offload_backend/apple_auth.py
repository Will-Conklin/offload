from __future__ import annotations

import jwt
from jwt import PyJWKClient


class AppleTokenValidationError(Exception):
    pass


class AppleTokenValidator:
    """Validates Apple Sign In identity tokens against Apple's public JWKS.

    Uses PyJWT's PyJWKClient which caches the public keys with a configurable TTL
    to avoid redundant JWKS fetches on every request.
    """

    APPLE_ISSUER = "https://appleid.apple.com"

    def __init__(
        self,
        *,
        jwks_url: str,
        audience: str,
        cache_ttl: int = 300,
    ):
        self._audience = audience
        self._jwks_client = PyJWKClient(
            jwks_url,
            timeout=10,
            cache_keys=True,
            max_cached_keys=16,
            lifespan=cache_ttl,
        )

    def validate(self, identity_token: str) -> str:
        """Validate an Apple Sign In identity token and return the stable user sub.

        Raises AppleTokenValidationError on any validation failure, including
        expired tokens, signature mismatches, and JWKS fetch errors.
        """
        try:
            signing_key = self._jwks_client.get_signing_key_from_jwt(identity_token)
            payload = jwt.decode(
                identity_token,
                signing_key.key,
                algorithms=["RS256"],
                audience=self._audience,
                issuer=self.APPLE_ISSUER,
            )
            sub = payload.get("sub")
            if not isinstance(sub, str) or not sub:
                raise AppleTokenValidationError("Missing sub claim in Apple identity token")
            return sub
        except jwt.ExpiredSignatureError as exc:
            raise AppleTokenValidationError("Apple identity token expired") from exc
        except jwt.InvalidTokenError as exc:
            raise AppleTokenValidationError("Invalid Apple identity token") from exc
        except AppleTokenValidationError:
            raise
        except Exception as exc:
            raise AppleTokenValidationError("Apple token validation failed") from exc
