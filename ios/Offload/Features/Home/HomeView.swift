// Purpose: Home feature placeholder view.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

import SwiftUI


struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                AppIcon(name: Icons.homeSelected, size: 48)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                VStack(spacing: Theme.Spacing.xs) {
                    Text("Home")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    Text("Home details are coming soon.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ThemeManager.shared)
}
