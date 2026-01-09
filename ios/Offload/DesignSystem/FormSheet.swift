//
//  FormSheet.swift
//  Offload
//
//  Created by Claude Code on 1/6/26.
//
//  Intent: Shared form sheet layout with consistent save/cancel behavior,
//  loading state, and inline error presentation across the app.
//

import SwiftUI

struct FormSheet<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let saveButtonTitle: String
    let isSaveDisabled: Bool
    let onSave: () async throws -> Void
    @ViewBuilder let content: () -> Content

    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                content()

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Theme.Typography.errorText)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        handleSave()
                    }
                    .disabled(isSaveDisabled || isSaving)
                }
            }
        }
    }

    private func handleSave() {
        isSaving = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                try await onSave()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
