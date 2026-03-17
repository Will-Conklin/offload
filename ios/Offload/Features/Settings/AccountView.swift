// Purpose: Settings and account feature views.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Avoid introducing feature logic that belongs in repositories.

import SwiftUI

struct AccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("userDisplayName") private var displayName = ""
    @State private var isEditingName = false

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
                preferencesSection
                tagsSection
                aboutSection
            }
            .listSectionSpacing(Theme.Spacing.lgSoft)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $isEditingName) {
            EditNameSheet(displayName: $displayName)
                .environmentObject(themeManager)
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
}
