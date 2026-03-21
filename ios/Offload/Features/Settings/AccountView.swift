// Purpose: Settings and account feature views.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Avoid introducing feature logic that belongs in repositories.

import AuthenticationServices
import SwiftUI

struct AccountView: View {
    var showsDismiss: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.aiBackendClient) private var backendClient
    @Environment(\.usageCounterStore) private var usageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("userDisplayName") private var displayName = ""
    @State private var isEditingName = false
    @State private var isSigningIn = false
    @State private var signInError: Error?
    @State private var showSignOutConfirm = false

    private static let allAIFeatures = AIQuotaConfig.allFeatures
    private static let totalQuota = AIQuotaConfig.cloudLimit

    private var style: ThemeStyle { themeManager.currentStyle }

    /// Derives up to two initials from the display name.
    private var initials: String {
        let words = displayName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        return words.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                signInSection
                preferencesSection
                aiUsageSection
                tagsSection
                aboutSection
            }
            .listSectionSpacing(Theme.Spacing.lgSoft)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if showsDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingName) {
            EditNameSheet(displayName: $displayName)
                .environmentObject(themeManager)
        }
        .alert("Sign In Failed", isPresented: .init(
            get: { signInError != nil },
            set: { if !$0 { signInError = nil } }
        )) {
            Button("OK") { signInError = nil }
        } message: {
            if let err = signInError { Text(err.localizedDescription) }
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { authManager.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll continue using the app anonymously.")
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section {
            Button {
                isEditingName = true
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    avatarView
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(displayName.isEmpty ? "Add your name" : displayName)
                            .font(Theme.Typography.body)
                            .foregroundStyle(
                                displayName.isEmpty
                                    ? Theme.Colors.textSecondary(colorScheme, style: style)
                                    : Theme.Colors.textPrimary(colorScheme, style: style)
                            )
                        Text("Tap to edit")
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    Spacer()
                    AppIcon(name: Icons.write, size: 14)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
            .buttonStyle(.plain)
            .rowStyle(.card)
            .accessibilityLabel(displayName.isEmpty ? "Add your name" : displayName)
            .accessibilityHint("Tap to edit your display name")
        } header: {
            Text("Profile")
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.accentPrimary(colorScheme, style: style))
                .frame(width: 56, height: 56)
            if initials.isEmpty {
                AppIcon(name: Icons.account, size: 24)
                    .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
            } else {
                Text(initials)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
            }
        }
    }

    @ViewBuilder
    private var signInSection: some View {
        switch authManager.authState {
        case .anonymous:
            Section {
                if isSigningIn {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
                        Spacer()
                    }
                    .rowStyle(.card)
                } else {
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName]
                    }, onCompletion: { result in
                        handleAppleSignIn(result)
                    })
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    .accessibilityLabel("Sign in with Apple")
                }

                Text("Optional. Your data stays on your device either way.")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    .rowStyle(.card)
            } header: {
                Text("Account")
            }

        case .authenticated(_, let displayName):
            Section {
                HStack(spacing: Theme.Spacing.sm) {
                    AppIcon(name: Icons.account, size: 16)
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    Text(displayName ?? "Apple Account")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    Spacer()
                    Text("Signed in")
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
                .rowStyle(.card)

                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    Text("Sign Out")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.destructive(colorScheme, style: style))
                }
                .rowStyle(.card)
                .accessibilityLabel("Sign out")
                .accessibilityHint("You'll continue using the app anonymously")
            } header: {
                Text("Account")
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                return
            }
            let name: String? = credential.fullName.flatMap { components in
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
                        displayName: name,
                        using: backendClient
                    )
                } catch {
                    signInError = error
                }
                isSigningIn = false
            }

        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationErrorDomain, nsError.code == 1001 { return }
            signInError = error
        }
    }

    private var preferencesSection: some View {
        Section {
            Picker("Appearance", selection: $themeManager.appearancePreference) {
                ForEach(AppearancePreference.allCases) { preference in
                    Text(preference.displayName).tag(preference)
                }
            }
            .pickerStyle(.menu)
            .rowStyle(.card)
        } header: {
            Text("Preferences")
        }
    }

    private var aiUsageSection: some View {
        let used = usageStore.totalMergedCount(for: Self.allAIFeatures)
        let quota = Self.totalQuota
        let progress = min(Double(used) / Double(quota), 1.0)
        let barColor: Color = used >= quota
            ? Theme.Colors.destructive(colorScheme, style: style)
            : used >= 80
                ? Theme.Colors.caution(colorScheme, style: style)
                : Theme.Colors.accentPrimary(colorScheme, style: style)

        return Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("\(used) of \(quota) AI actions used this month")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(Theme.Colors.textSecondary(colorScheme, style: style).opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(barColor)
                            .frame(width: max(6.0, geo.size.width * progress), height: 6)
                    }
                }
                .frame(height: 6)

                Text("AI features help you organize and decide. Usage resets monthly.")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .padding(.vertical, Theme.Spacing.xs)
            .rowStyle(.card)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(used) of \(quota) AI actions used this month")
            .accessibilityValue(used >= quota ? "Limit reached" : "\(quota - used) remaining")
        } header: {
            Text("AI Usage")
        }
    }

    private var tagsSection: some View {
        Section {
            NavigationLink {
                TagManagementView()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    IconTile(
                        iconName: Icons.tag,
                        iconSize: 16,
                        tileSize: 44,
                        style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                    )
                    Text("Tags")
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    Spacer()
                }
            }
            .rowStyle(.card)
        } header: {
            Text("Tags")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .rowStyle(.card)

            Link(destination: URL(string: "https://github.com/Will-Conklin/offload")!) {
                HStack {
                    Text("GitHub")
                    Spacer()
                    AppIcon(name: Icons.externalLink, size: 12)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
            .rowStyle(.card)
        } header: {
            Text("About")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - Edit Name Sheet

private struct EditNameSheet: View {
    @Binding var displayName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var name = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Your name", text: $name)
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .toolbarBackground(Theme.Colors.background(colorScheme, style: style), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                }
            }
            .onAppear { name = displayName }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthManager.shared)
}
