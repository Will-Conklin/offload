// Intent: Provide a low-friction capture flow with immediate focus and reassuring copy aligned to ADHD-friendly guardrails.
//
//  CaptureView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

/// Legacy placeholder capture view
/// Use CaptureSheetView for the actual app (supports voice + text)
struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String = ""
    @State private var notes: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Capture") {
                    TextField("What's on your mind?", text: $title, axis: .vertical)
                        .focused($isFocused)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .font(.headline)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                }

                Section {
                    Label("Captured items can be organized later. Undo is available from the inbox.",
                          systemImage: "checkmark.seal")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                        .padding(.vertical, Theme.Spacing.xs)
                }

                // TODO: Add capture type selection (task, note, idea, etc.)
                // TODO: Add quick tags/categories
                // TODO: Add priority selection
                // TODO: Add due date picker
                // TODO: Add voice memo recording
                // TODO: Add photo/file attachment
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                    } label: {
                        Text("Capture & close")
                            .fontWeight(.semibold)
                    }
                    .disabled(title.isEmpty)
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .onAppear {
                isFocused = true
            }
        }
    }

    private func saveEntry() {
        withAnimation {
            let combinedText = notes.isEmpty ? title : "\(title)\n\n\(notes)"
            let entry = CaptureEntry(
                rawText: combinedText,
                inputType: .text,
                source: .app
            )
            modelContext.insert(entry)
            dismiss()
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(PersistenceController.preview)
}
