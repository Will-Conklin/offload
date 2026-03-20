"""Tests for Apple identity token (JWT) verification."""

import time
from unittest.mock import AsyncMock, patch

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa

from offload_backend.apple_jwt import verify_apple_identity_token

APPLE_ISSUER = "https://appleid.apple.com"
TEST_AUDIENCE = "wc.Offload"
TEST_KID = "test-key-1"
TEST_SUB = "001234.abcdef1234567890.0123"


@pytest.fixture()
def rsa_keypair():
    """Generate an RSA key pair for signing test tokens."""
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()
    return private_key, public_key


@pytest.fixture()
def jwks_response(rsa_keypair):
    """Build a JWKS dict from the test RSA public key."""
    _, public_key = rsa_keypair
    # Export public key numbers to build JWK manually
    from jwt.algorithms import RSAAlgorithm

    jwk_dict = RSAAlgorithm.to_jwk(public_key, as_dict=True)
    jwk_dict["kid"] = TEST_KID
    jwk_dict["alg"] = "RS256"
    jwk_dict["use"] = "sig"
    return {"keys": [jwk_dict]}


def _make_token(
    private_key,
    *,
    sub=TEST_SUB,
    aud=TEST_AUDIENCE,
    iss=APPLE_ISSUER,
    exp_offset=3600,
    kid=TEST_KID,
):
    """Create a signed JWT with the given claims."""
    now = int(time.time())
    payload = {
        "sub": sub,
        "aud": aud,
        "iss": iss,
        "iat": now,
        "exp": now + exp_offset,
    }
    return jwt.encode(payload, private_key, algorithm="RS256", headers={"kid": kid})


@pytest.mark.asyncio
async def test_verify_valid_apple_token(rsa_keypair, jwks_response):
    """Valid token returns the sub claim."""
    private_key, _ = rsa_keypair
    token = _make_token(private_key)

    with patch(
        "offload_backend.apple_jwt._fetch_apple_jwks",
        new_callable=AsyncMock,
        return_value=jwks_response,
    ):
        result = await verify_apple_identity_token(token, expected_audience=TEST_AUDIENCE)

    assert result == TEST_SUB


@pytest.mark.asyncio
async def test_verify_rejects_wrong_audience(rsa_keypair, jwks_response):
    """Token with wrong audience raises ValueError."""
    private_key, _ = rsa_keypair
    token = _make_token(private_key, aud="com.wrong.app")

    with patch(
        "offload_backend.apple_jwt._fetch_apple_jwks",
        new_callable=AsyncMock,
        return_value=jwks_response,
    ):
        with pytest.raises(ValueError, match="Invalid audience"):
            await verify_apple_identity_token(token, expected_audience=TEST_AUDIENCE)


@pytest.mark.asyncio
async def test_verify_rejects_wrong_issuer(rsa_keypair, jwks_response):
    """Token with wrong issuer raises ValueError."""
    private_key, _ = rsa_keypair
    token = _make_token(private_key, iss="https://evil.example.com")

    with patch(
        "offload_backend.apple_jwt._fetch_apple_jwks",
        new_callable=AsyncMock,
        return_value=jwks_response,
    ):
        with pytest.raises(ValueError, match="Invalid issuer"):
            await verify_apple_identity_token(token, expected_audience=TEST_AUDIENCE)


@pytest.mark.asyncio
async def test_verify_rejects_expired_token(rsa_keypair, jwks_response):
    """Expired token raises ValueError."""
    private_key, _ = rsa_keypair
    token = _make_token(private_key, exp_offset=-3600)

    with patch(
        "offload_backend.apple_jwt._fetch_apple_jwks",
        new_callable=AsyncMock,
        return_value=jwks_response,
    ):
        with pytest.raises(ValueError, match="expired"):
            await verify_apple_identity_token(token, expected_audience=TEST_AUDIENCE)
