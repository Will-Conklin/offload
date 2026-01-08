//
//  CapturesView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Primary view for raw thought captures awaiting organization.
//  Displays lifecycle state and input type with minimal UI friction.
//

import SwiftUI
import SwiftData

struct CapturesView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showingCapture = false
    @State private var workflowService: CaptureWorkflowService?
    @State private var entries: [CaptureEntry] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            ForEach(entries) { entry in
                CaptureRow(entry: entry)
            }
            .onDelete(perform: deleteEntries)
        }
        .navigationTitle("Captures")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCapture = true
                } label: {
                    Label("Capture", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingCapture, onDismiss: {
            _Concurrency.Task {
                await loadInbox()
            }
        }) {
            CaptureSheetView()
        }
        .task {
            if workflowService == nil {
                workflowService = CaptureWorkflowService(modelContext: modelContext)
            }
            await loadInbox()
        }
        .refreshable {
            await loadInbox()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private func loadInbox() async {
        guard let workflowService = workflowService else { return }
        do {
            entries = try workflowService.fetchInbox()
        } catch {
            // Error is already set in workflowService.errorMessage
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        guard let workflowService = workflowService else { return }

        // Capture entries to delete BEFORE async operation
        let entriesToDelete = offsets.map { entries[$0] }

        _Concurrency.Task {
            do {
                // Serialize deletions
                for entry in entriesToDelete {
                    try await workflowService.deleteEntry(entry)
                }

                // Single reload after all deletions complete
                await loadInbox()
            } catch {
                // Show error to user
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct CaptureRow: View {
    let entry: CaptureEntry

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.rawText)
                .font(Theme.Typography.body)
                .lineLimit(2)

            HStack {
                Text(entry.createdAt, format: .dateTime)
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

                if entry.entryInputType == .voice {
                    Image(systemName: "waveform")
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }

                if entry.currentLifecycleState != .raw {
                    Text(entry.currentLifecycleState.rawValue)
                        .font(Theme.Typography.badge)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.accentPrimary(colorScheme).opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        CapturesView()
    }
    .modelContainer(PersistenceController.preview)
}
