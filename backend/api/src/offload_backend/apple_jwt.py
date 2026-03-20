"""Apple identity token (JWT) verification using Apple's JWKS."""

import time

import httpx
import jwt

APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

_jwks_cache: dict | None = None
_jwks_cache_time: float = 0.0
_JWKS_CACHE_TTL = 86400  # 24 hours


async def _fetch_apple_jwks() -> dict:
    """Fetch Apple's JWKS, with 24-hour in-memory cache and key-miss refresh."""
    global _jwks_cache, _jwks_cache_time
    now = time.monotonic()
    if _jwks_cache is not None and (now - _jwks_cache_time) < _JWKS_CACHE_TTL:
        return _jwks_cache
    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_JWKS_URL, timeout=10)
        resp.raise_for_status()
        _jwks_cache = resp.json()
        _jwks_cache_time = now
        return _jwks_cache


def _invalidate_jwks_cache() -> None:
    """Force next fetch to refresh the cache (used on key-miss)."""
    global _jwks_cache, _jwks_cache_time
    _jwks_cache = None
    _jwks_cache_time = 0.0


async def verify_apple_identity_token(token: str, *, expected_audience: str) -> str:
    """Verify an Apple identity token and return the Apple user ID (sub claim).

    Args:
        token: The identity token JWT from ASAuthorizationAppleIDCredential.
        expected_audience: The app's bundle ID (e.g., 'wc.Offload').

    Returns:
        The Apple user ID (sub claim) from the verified token.

    Raises:
        ValueError: If the token is invalid, expired, or has wrong issuer/audience.
    """
    jwks_data = await _fetch_apple_jwks()
    jwk_client = jwt.PyJWKSet.from_dict(jwks_data)

    try:
        unverified_header = jwt.get_unverified_header(token)
        kid = unverified_header.get("kid")
        if not kid:
            msg = "Token missing kid header"
            raise ValueError(msg)

        signing_key = None
        for key in jwk_client.keys:
            if key.key_id == kid:
                signing_key = key
                break

        if signing_key is None:
            _invalidate_jwks_cache()
            jwks_data = await _fetch_apple_jwks()
            jwk_client = jwt.PyJWKSet.from_dict(jwks_data)
            for key in jwk_client.keys:
                if key.key_id == kid:
                    signing_key = key
                    break

        if signing_key is None:
            msg = f"No matching key found for kid={kid}"
            raise ValueError(msg)

        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=expected_audience,
            issuer=APPLE_ISSUER,
        )

        sub = payload.get("sub")
        if not sub:
            msg = "Token missing sub claim"
            raise ValueError(msg)

        return sub

    except jwt.ExpiredSignatureError:
        msg = "Apple identity token expired"
        raise ValueError(msg) from None
    except jwt.InvalidAudienceError:
        msg = f"Invalid audience: expected {expected_audience}"
        raise ValueError(msg) from None
    except jwt.InvalidIssuerError:
        msg = f"Invalid issuer: expected {APPLE_ISSUER}"
        raise ValueError(msg) from None
    except jwt.PyJWTError as e:
        msg = f"Invalid Apple identity token: {e}"
        raise ValueError(msg) from None
