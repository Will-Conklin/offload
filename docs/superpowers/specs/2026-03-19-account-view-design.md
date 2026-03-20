# Account View Design Spec

## Overview

Build out the AccountView from its current placeholder into a full account screen with Sign in with Apple authentication, usage/quota display, cloud AI consent, app preferences, and about/support info. Merges SettingsView into AccountView (SettingsView is deleted).

## Auth Architecture

### AuthManager

`ObservableObject` class owning the auth lifecycle. Injected via `@EnvironmentObject` from `AppRootView` (matches existing `ThemeManager` pattern).

**States:**

- `.signedOut` — no credentials, show sign-in CTA
- `.signingIn` — Apple auth sheet is presented
- `.signedIn(AppleUser)` — authenticated, show full account screen

**AppleUser model** (lightweight struct, not SwiftData):

- `userId: String` — Apple's stable user identifier (`sub` claim)
- `fullName: String?` — only provided on first sign-in
- `email: String?` — only provided on first sign-in

**Sign-in flow:**

1. User taps Sign in with Apple → `ASAuthorizationAppleIDProvider` presents native sheet
2. On success, receive `ASAuthorizationAppleIDCredential` with identity token (JWT)
3. Send identity token to `POST /v1/sessions/apple`
4. Backend verifies JWT against Apple's JWKS, extracts `sub`
5. Backend returns authenticated session token (existing format + `apple_user_id` claim)
6. Store Apple user ID + name + email in Keychain
7. Store session token in `SessionTokenStore`
8. Transition to `.signedIn`

**Persistence on launch:**

1. Check Keychain for stored Apple user ID
2. If found, call `ASAuthorizationAppleIDProvider.getCredentialState(forUserID:)`
3. If `.authorized` → refresh session via `POST /v1/sessions/refresh`, transition to `.signedIn`
4. If `.revoked` or `.notFound` → clear Keychain, stay `.signedOut`

**Sign out:** Clear Keychain + session token, reset to `.signedOut`.

**Token refresh:** Apple identity tokens are one-time-use JWTs — they cannot be reused for re-authentication. Instead, we use a dedicated refresh endpoint:

- `POST /v1/sessions/refresh` accepts an expired-but-valid-signature session token
- Backend verifies the signature is valid (proves we issued it), checks the `apple_user_id` or `install_id` claim
- Returns a new session token with a fresh expiry
- If the session token is too old (e.g., >30 days), refuse and require a new Sign in with Apple flow
- On launch (credential still authorized), AuthManager calls refresh with the last session token from Keychain
- During use, if a session expires, `NetworkAIBackendClient` calls refresh transparently before retrying the AI request

**Backend user persistence:** Explicitly out of scope. No `users` table. Auth is for identity verification only. Usage tracking remains per-install (tied to `install_id`), not per-Apple-user. A future phase could link usage across devices via `apple_user_id`.

### Backend: POST /v1/sessions/apple

New router at `routers/sessions_apple.py`.

**Request:**

```json
{
  "identity_token": "eyJ...",
  "install_id": "device-uuid",
  "app_version": "1.0.0",
  "platform": "ios"
}
```

**Processing:**

1. Fetch Apple's JWKS from `https://appleid.apple.com/auth/keys` (in-memory cache, 24-hour TTL, refresh on key-miss before failing)
2. Verify identity token signature (RS256) using matching key
3. Validate claims: `iss` = `https://appleid.apple.com`, `aud` = configured bundle ID (new config field `OFFLOAD_APPLE_BUNDLE_ID`, default `wc.Offload`)
4. Extract `sub` as Apple user ID
5. Create session token with optional `apple_user_id` claim (see SessionClaims changes below)

**Response:**

```json
{
  "session_token": "v2:...",
  "expires_at": "2026-03-19T12:00:00Z"
}
```

Response schema is identical to `AnonymousSessionResponse` — reuse as `SessionResponse`.

**New dependency:** `PyJWT` with `cryptography` for RS256 verification.

### Backend: POST /v1/sessions/refresh

New endpoint in `routers/sessions_apple.py`.

**Request:**

```json
{
  "session_token": "v2:...",
  "install_id": "device-uuid"
}
```

**Processing:**

1. Verify the session token signature (proves we issued it), allow expired tokens
2. Validate `install_id` matches the token's claim
3. Reject if token is older than 30 days (require fresh Sign in with Apple)
4. Issue a new session token with same claims and fresh expiry

**Response:** Same `SessionResponse` schema.

### SessionClaims Extension

Add optional `apple_user_id: str | None = None` to the existing `SessionClaims` Pydantic model. This is backwards-compatible — anonymous sessions have `apple_user_id = None`, authenticated sessions populate it.

**Implementation details:**

- Do NOT add `apple_user_id` to `REQUIRED_V2_CLAIMS` — it is only present in authenticated sessions
- Update `_parse_v2_claims` to extract `apple_user_id` when present in payload (use `.get()` with `None` default)
- Update `issue_session(install_id, ttl_seconds, apple_user_id=None)` — add optional parameter, include in payload when not `None`
- Update `encode()` to include `apple_user_id` in the claims dict when populated
- Add `decode(token, allow_expired=False)` parameter — when `True`, skip expiry check but still verify HMAC signature. Used only by the refresh endpoint. Default `False` preserves current behavior.

### Config Addition

Add `OFFLOAD_APPLE_BUNDLE_ID: str = "wc.Offload"` to `Settings` in `config.py`.

### iOS Protocol & Contract Signatures

New `AIBackendClient` protocol method:

```swift
func createAppleSession(identityToken: String) async throws
```

New contract types in `AIBackendContracts.swift`:

```swift
struct AppleSessionRequest: Codable {
    let identityToken: String
    let installId: String
    let appVersion: String
    let platform: String
}

struct SessionRefreshRequest: Codable {
    let sessionToken: String
    let installId: String
}
```

Rename `AnonymousSessionResponse` → `SessionResponse` (used by anonymous, apple, and refresh endpoints). Update references in `schemas.py`, anonymous session router, `AIBackendClient.swift` protocol + implementation, and `AIBackendContracts.swift`.

### Session Token Persistence

Replace `InMemorySessionTokenStore` with a `KeychainSessionTokenStore` that persists `token` and `expiresAt` in Keychain alongside the Apple user credentials. Required for launch-time refresh (AuthManager needs the last session token to call `POST /v1/sessions/refresh`).

### Rate Limiting

Both `POST /v1/sessions/apple` and `POST /v1/sessions/refresh` must go through the existing `session_rate_limiter` — they issue session tokens just like the anonymous endpoint.

## AccountView UI

### Signed-Out State

Centered hero layout, full-screen MCM background:

- Account icon in bordered circle
- "YOUR ACCOUNT" heading (Bebas Neue)
- Value prop: "Sign in to track your AI usage, sync preferences, and manage your data."
- Native `SignInWithAppleButton` (SwiftUI `ASAuthorizationAppleIDButton`)
- Version number at bottom
- No other controls

### Signed-In State

Scrollable `NavigationStack` with flat card sections (each section its own bordered card):

1. **Profile card** — accent gradient background, initial-based avatar circle, name + email
2. **AI Usage card** — "AI USAGE" header (Bebas Neue), progress bar per feature (breakdowns, brain dumps, decisions) showing `used / quota`
3. **Cloud AI card** — toggle row with label and description
4. **Appearance card** — theme picker row (moved from SettingsView)
5. **Manage Tags card** — row with tag count, NavigationLink to tag management (moved from SettingsView)
6. **About card** — version, privacy policy link, send feedback link
7. **Sign Out** — text button, shows confirmation alert before signing out

### Navigation

- Tags and appearance open as pushed views within the NavigationStack
- Everything else is inline (toggles, display-only)
- No sheets

## Data Flow

### Usage Display

- On `AccountView.onAppear` (when signed in): reconcile usage for each feature via `AIBackendClient.reconcileUsage()`
- Display `mergedCount` against total quota (`effectiveRemaining + mergedCount`)
- No polling — refreshes each time the view appears
- Offline: show last-known local counts, no error state

### Cloud AI Consent

- Toggle reads/writes `UserDefaultsCloudAIConsentStore.isOptedIn`
- No backend call — local preference sent as header on AI requests

### Dependency Injection

- `AuthManager` created as `@StateObject` in `AppRootView`, passed via `.environmentObject()` (matches `ThemeManager` pattern)
- `NetworkAIBackendClient.refreshSession()` must check `AuthManager.state` — if signed in, call `POST /v1/sessions/refresh` instead of creating a new anonymous session (prevents silent auth downgrade)

## Error Handling

| Scenario | Behavior |
|----------|----------|
| User cancels Apple sign-in | Silently stay on signed-out screen |
| Apple auth OK, backend fails | Toast: "Couldn't connect to server. Try again later." Stay signed out |
| Network timeout on sign-in | Same toast, no retry loop |
| Token expires during use | `NetworkAIBackendClient` calls `POST /v1/sessions/refresh` transparently |
| Refresh token too old (>30 days) | Require new Sign in with Apple flow, show sign-in screen |
| Re-auth fails (network down) | AI call fails with existing error handling, no sign-out |
| Apple credential revoked | Clear Keychain on next launch, user sees signed-out screen |
| Name/email unavailable (reinstall) | Show "Apple User" fallback, no email displayed |
| Usage data offline | Show stale local counts, no error state |

## Files Changed

| Action | File |
|--------|------|
| Create | `ios/Offload/Data/Services/AuthManager.swift` |
| Rewrite | `ios/Offload/Features/Settings/AccountView.swift` |
| Create | `ios/Offload/Features/Settings/TagManagementView.swift` — extracted from SettingsView |
| Delete | `ios/Offload/Features/Settings/SettingsView.swift` |
| Edit | `ios/Offload/App/AppRootView.swift` — inject AuthManager as `@StateObject` + `.environmentObject()` |
| Edit | `ios/Offload/App/MainTabView.swift` — remove SettingsView refs |
| Edit | `ios/Offload/Data/Networking/AIBackendClient.swift` — add `createAppleSession(identityToken:)`, `refreshSession()` auth-aware logic, add `AIBackendClient` protocol method |
| Edit | `ios/Offload/Data/Networking/AIBackendContracts.swift` — add `AppleSessionRequest`, `SessionRefreshRequest`, rename `AnonymousSessionResponse` → `SessionResponse` |
| Create | `ios/Offload/Data/Networking/KeychainSessionTokenStore.swift` — Keychain-backed token persistence |
| Create | `backend/api/src/offload_backend/routers/sessions_apple.py` — apple auth + refresh endpoints |
| Edit | `backend/api/src/offload_backend/main.py` — register new router |
| Edit | `backend/api/src/offload_backend/security.py` — optional `apple_user_id` in `SessionClaims`, `allow_expired` param on `decode()` |
| Edit | `backend/api/src/offload_backend/config.py` — add `OFFLOAD_APPLE_BUNDLE_ID` |
| Edit | `backend/api/src/offload_backend/schemas.py` — rename `AnonymousSessionResponse` → `SessionResponse` |
| Edit | `backend/api/src/offload_backend/routers/sessions.py` — update to use renamed `SessionResponse` |
| Edit | `backend/api/pyproject.toml` — add PyJWT + cryptography |
