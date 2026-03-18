---
id: plan-authentication
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - ios
  - backend
  - security
last_updated: 2026-03-17
related:
  - plan-backend-session-security-hardening
depends_on:
  - docs/plans/plan-backend-session-security-hardening.md
supersedes: []
accepted_by: "@Will-Conklin"
accepted_at: 2026-03-17
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Authentication — Keychain Sessions + Sign In with Apple

## Overview

Two-phase authentication implementation. Phase 1 persists anonymous backend session
tokens in the iOS Keychain so they survive app termination. Phase 2 adds optional Sign
In with Apple, giving users a persistent Apple-ID-backed identity without removing or
requiring the anonymous path.

Both phases respect the product philosophy: **no account required**, anonymous path
always available, Sign In with Apple is optional.

## Goals

- Prevent unnecessary anonymous session creation on every app relaunch (Phase 1).
- Establish a stable, Apple-ID-backed user identity for authenticated sessions (Phase 2).
- Preserve backward compatibility: anonymous tokens continue to work unchanged.
- Provide a skippable first-launch onboarding surface for Sign In with Apple.

## Phases

### Phase 1: Keychain Session Token Persistence

**Status:** Completed

**iOS changes:**

- [x] `KeychainSessionTokenStore` implementing `SessionTokenStore` protocol, stored under
      `wc.Offload / anonymous_session_token` with `afterFirstUnlockThisDeviceOnly` access.
      Loads from Keychain on init; persists when both token and expiry are set.
- [x] `NetworkAIBackendClient` default init now uses `KeychainSessionTokenStore`.
- [x] `KeychainSessionTokenStoreTests`: store/retrieve, persist across instances,
      clear, nil-setting, partial set, overwrite.
- [x] `AIBackendClientTests.testKeychainTokenSurvivesReinstantiation`: cached token
      skips `createAnonymousSession` on relaunch.

**Backend changes:** None.

### Phase 2: Sign In with Apple (Optional Identity)

**Status:** Completed

**Backend changes:**

- [x] `POST /v1/auth/apple` — validates Apple identity token via Apple JWKS (PyJWT[crypto]),
      upserts user record, issues Offload session token with `user_id` claim.
- [x] `SQLiteUserStore` — `users` table in usage DB: `user_id` (UUID), `apple_user_id`
      (UNIQUE), `install_id`, `display_name`. `upsert_by_apple_id` preserves existing
      display name when new value is None.
- [x] `AppleTokenValidator` — JWKS-backed RS256 validation via `PyJWKClient` with
      5-minute key cache. Raises `AppleTokenValidationError` on any failure.
- [x] `SessionClaims.user_id: str | None = None` — optional field, backward compatible.
      Anonymous tokens (no `user_id`) continue to decode and validate correctly.
- [x] `TokenManager.encode` includes `user_id` in payload when present.
- [x] `pyproject.toml` — added `PyJWT[crypto]>=2.9.0`.
- [x] `config.py` — `apple_bundle_id` and `apple_jwks_url` settings.
- [x] Backend tests: `test_auth.py` (7 tests), `test_user_store.py` (6 tests). All passing.

**iOS changes:**

- [x] `AppleAuthRequest` / `AppleAuthResponse` Codable contracts.
- [x] `AIBackendClient` protocol + `NetworkAIBackendClient.signInWithApple` —
      calls `POST /v1/auth/apple`, writes authenticated session token to
      `KeychainSessionTokenStore`.
- [x] `AuthManager` (`@MainActor ObservableObject`) — manages `AuthState`
      (`.anonymous` / `.authenticated(userId:displayName:)`). `signInWithApple` calls
      backend and persists user identity in `KeychainAuthStore`. `signOut` clears both.
- [x] `KeychainAuthStore` — static Keychain helpers for auth identity
      (`wc.Offload / apple_auth_identity`).
- [x] `OnboardingView` — first-launch full-screen sheet with `SignInWithAppleButton`
      and "Skip — continue anonymously" escape. Shown once via
      `@AppStorage("hasCompletedOnboarding")`. User cancellation (ASAuthorizationError
      1001) treated as skip.
- [x] `AccountView` — new Account section: anonymous shows SIWA button + privacy
      caption; authenticated shows display name + sign-out confirmation.
- [x] `AppRootView` — onboarding gate sheet bound to `hasCompletedOnboarding`.
- [x] `OffloadApp` — `AuthManager.shared` injected as `@EnvironmentObject`.
- [x] `AuthManagerTests` — 10 tests covering KeychainAuthStore CRUD, AuthManager state
      transitions, sign-in/sign-out, Keychain persistence.

## Dependencies

- `plan-backend-session-security-hardening` — token v2 format and key management on
  which `user_id` claim extension is built.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Apple JWKS unavailable at sign-in | M | `AppleTokenValidationError` surfaces to UI; user can retry or skip |
| Apple identity token not provided on re-auth | L | Only `sub` (user ID) is required; name is only available on first sign-in and preserved in DB |
| Keychain item inaccessible after device restore | L | Falls back to anonymous session; user can sign in again |
| Benchmark test flaky in CI | L | Pre-existing; unrelated to auth changes |

## User Verification

- [ ] Force-quit app, relaunch — no new session request in network log.
- [ ] First launch → onboarding sheet appears; skip → anonymous.
- [ ] First launch → sign in with Apple → authenticated state shown in Account tab.
- [ ] Authenticated AI call — backend receives session token with `user_id` claim.
- [ ] Re-install → sign in with same Apple ID → same `user_id` returned.
- [ ] Sign out → anonymous state; Keychain identity cleared.
- [ ] `docs/product.md` updated to reflect optional Sign In with Apple.

## Progress

| Date | Update |
| --- | --- |
| 2026-03-17 | Plan created. Phase 1 (KeychainSessionTokenStore) completed and pushed. Phase 2 (Sign In with Apple) completed and pushed. |
