//
//  Components.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(Theme.CornerRadius.md)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Color.blue, lineWidth: 2)
                )
        }
    }
}

// TODO: Add more button variants (text, icon, floating action, etc.)

// MARK: - Cards

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.Spacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(radius: 2)
    }
}

// TODO: Add more card variants

// MARK: - Input Fields

// TODO: Add custom TextField component
// TODO: Add custom TextEditor component
// TODO: Add DatePicker component
// TODO: Add Picker component
// TODO: Add Toggle component

// MARK: - Navigation

// TODO: Add custom NavigationBar component
// TODO: Add TabBar component
// TODO: Add BottomSheet component
// TODO: Add Modal component

// MARK: - Feedback

// TODO: Add LoadingView component
// TODO: Add EmptyStateView component
// TODO: Add ErrorView component
// TODO: Add Toast/Snackbar component
// TODO: Add ProgressIndicator component
