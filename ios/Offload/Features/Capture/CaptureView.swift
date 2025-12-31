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

    @State private var title: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Capture") {
                    TextField("What's on your mind?", text: $title)
                        .font(.headline)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
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
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        withAnimation {
            let combinedText = notes.isEmpty ? title : "\(title)\n\n\(notes)"
            let entry = BrainDumpEntry(
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
