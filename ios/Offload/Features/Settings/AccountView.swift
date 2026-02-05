// Purpose: Settings and account feature views.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Avoid introducing feature logic that belongs in repositories.

//  Placeholder account view for profile settings

import SwiftUI

struct AccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                AppIcon(name: Icons.account, size: 48)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                VStack(spacing: Theme.Spacing.xs) {
                    Text("Account")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    Text("Account settings are coming soon.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        IconTile(
                            iconName: Icons.settings,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(themeManager)
            }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(ThemeManager.shared)
}
