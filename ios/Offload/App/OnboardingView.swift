// Purpose: First-launch onboarding sheet presenting optional Sign In with Apple.
// Authority: Code-level
// Governed by: CLAUDE.md

import AuthenticationServices
import SwiftUI

/// Shown once on first launch. Sign In with Apple is optional — users can skip
/// and continue with an anonymous session at any time.
struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.aiBackendClient) private var backendClient
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSigningIn = false
    @State private var signInError: Error?

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            headerSection
            Spacer()
            signInSection
            Spacer(minLength: Theme.Spacing.xl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Surface.background(colorScheme, style: style))
        .interactiveDismissDisabled(true)
        .alert("Sign In Failed", isPresented: .init(
            get: { signInError != nil },
            set: { if !$0 { signInError = nil } }
        )) {
            Button("OK") { signInError = nil }
        } message: {
            if let err = signInError {
                Text(err.localizedDescription)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Offload")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

            Text("Get it out of your head.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .multilineTextAlignment(.center)
        }
    }

    private var signInSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if isSigningIn {
                ProgressView()
                    .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
                    .padding(.vertical, Theme.Spacing.md)
            } else {
                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName]
                }, onCompletion: { result in
                    handleAppleSignIn(result)
                })
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                .accessibilityLabel("Sign in with Apple")
            }

            Button {
                onComplete()
            } label: {
                Text("Skip — continue anonymously")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    .underline()
            }
            .disabled(isSigningIn)
            .accessibilityLabel("Skip sign in")
            .accessibilityHint("Continue using the app without an account")

            Text("Optional. Your data stays on your device either way.")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Private

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                signInError = AuthOnboardingError.missingCredential
                return
            }
            let displayName: String? = credential.fullName.flatMap { components in
                let formatted = PersonNameComponentsFormatter.localizedString(
                    from: components, style: .default
                )
                return formatted.isEmpty ? nil : formatted
            }
            let installId = DeviceInfo.installId

            isSigningIn = true
            Task {
                do {
                    try await authManager.signInWithApple(
                        identityToken: identityToken,
                        installId: installId,
                        displayName: displayName,
                        using: backendClient
                    )
                    onComplete()
                } catch {
                    signInError = error
                }
                isSigningIn = false
            }

        case .failure(let error):
            let nsError = error as NSError
            // ASAuthorizationError.canceled (1001) — user dismissed; treat as skip
            if nsError.domain == ASAuthorizationErrorDomain, nsError.code == 1001 {
                return
            }
            signInError = error
        }
    }
}

private enum AuthOnboardingError: LocalizedError {
    case missingCredential

    var errorDescription: String? {
        "Could not retrieve Apple credentials. Please try again."
    }
}
