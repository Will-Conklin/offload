//
//  InboxView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Primary inbox for raw brain dump entries awaiting organization.
//  Displays lifecycle state and input type with minimal UI friction.
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showingCapture = false
    @State private var workflowService: BrainDumpWorkflowService?
    @State private var entries: [BrainDumpEntry] = []

    var body: some View {
        List {
            ForEach(entries) { entry in
                BrainDumpRow(entry: entry)
            }
            .onDelete(perform: deleteEntries)
        }
        .navigationTitle("Inbox")
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
                workflowService = BrainDumpWorkflowService(modelContext: modelContext)
            }
            await loadInbox()
        }
        .refreshable {
            await loadInbox()
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

        withAnimation {
            for index in offsets {
                let entry = entries[index]
                _Concurrency.Task {
                    do {
                        try await workflowService.deleteEntry(entry)
                        await loadInbox()
                    } catch {
                        // Error is already set in workflowService.errorMessage
                    }
                }
            }
        }
    }
}

struct BrainDumpRow: View {
    let entry: BrainDumpEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.rawText)
                .font(.body)
                .lineLimit(2)

            HStack {
                Text(entry.createdAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if entry.entryInputType == .voice {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if entry.currentLifecycleState != .raw {
                    Text(entry.currentLifecycleState.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        InboxView()
    }
    .modelContainer(PersistenceController.preview)
}
