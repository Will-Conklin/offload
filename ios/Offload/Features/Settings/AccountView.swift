//
//  AccountView.swift
//  Offload
//
//  Placeholder account view for profile settings
//

import SwiftUI

// AGENT NAV
// - Layout
// - Content

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(ThemeManager.shared)
}
