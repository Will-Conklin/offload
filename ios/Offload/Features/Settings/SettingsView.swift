// Purpose: Settings and account feature views.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Avoid introducing feature logic that belongs in repositories.

//  Simple flat settings: theme picker, tags/categories, basic info

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                // Appearance section
                Section {
                    Picker("Appearance", selection: $themeManager.appearancePreference) {
                        ForEach(AppearancePreference.allCases) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                    .pickerStyle(.menu)
                    .rowStyle(.card)
                } header: {
                    Text("Appearance")
                }

                // Tags section
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

                // About section
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
            .listSectionSpacing(Theme.Spacing.lgSoft)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

#Preview {
    SettingsView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
