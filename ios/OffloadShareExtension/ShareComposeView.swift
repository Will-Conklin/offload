// Purpose: SwiftUI compose view shown inside the Share Extension.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep UI minimal (≤120 MB memory limit). No SwiftData — write to PendingCaptureStore only.

import SwiftUI

/// Compact compose view shown when the user picks Offload from any app's share sheet.
struct ShareComposeView: View {
    @State private var text: String
    private let sourceURL: String?
    private let onSave: (String, String?) -> Void
    private let onCancel: () -> Void

    @State private var selectedType: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    private static let itemTypes: [(label: String, value: String)] = [
        ("Task", "task"), ("Note", "note"), ("Idea", "idea"),
        ("Link", "link"), ("Question", "question"), ("Decision", "decision"),
    ]

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        initialContent: String,
        sourceURL: String?,
        onSave: @escaping (String, String?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _text = State(initialValue: initialContent)
        self.sourceURL = sourceURL
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Text input
                TextEditor(text: $text)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("What's on your mind?")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, 18)
                                .padding(.leading, 15)
                                .allowsHitTesting(false)
                        }
                    }

                if let url = sourceURL, !url.isEmpty {
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                }

                // Type chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.itemTypes, id: \.value) { type in
                            let isSelected = selectedType == type.value
                            Button {
                                selectedType = isSelected ? nil : type.value
                            } label: {
                                Text(type.label)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Offload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .keyboardShortcut(".", modifiers: .command)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmed, selectedType)
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!canSave)
                }
            }
        }
    }
}
