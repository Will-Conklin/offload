//
//  ContentView.swift
//  offload
//
//  Created by William Conklin on 12/30/25.
//

import SwiftUI
import SwiftData

/// Legacy demo view - kept for reference
/// Use InboxView for the actual app
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [CaptureEntry]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        Text("Entry: \(entry.rawText)")
                    } label: {
                        Text(entry.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addEntry) {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an entry")
        }
    }

    private func addEntry() {
        withAnimation {
            let newEntry = CaptureEntry(
                rawText: "Demo entry at \(Date())",
                inputType: .text,
                source: .app
            )
            modelContext.insert(newEntry)
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

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview)
}
