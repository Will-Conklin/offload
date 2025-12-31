//
//  InboxView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrainDumpEntry.createdAt, order: .reverse) private var entries: [BrainDumpEntry]

    @State private var showingCapture = false

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
        .sheet(isPresented: $showingCapture) {
            CaptureSheetView()
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
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
