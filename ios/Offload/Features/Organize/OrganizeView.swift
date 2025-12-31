//
//  OrganizeView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

struct OrganizeView: View {
    @Query private var items: [Item]

    var body: some View {
        NavigationStack {
            List {
                // TODO: Implement project/category sections
                Section("Projects") {
                    Text("No projects yet")
                        .foregroundStyle(.secondary)
                }

                Section("Categories") {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                }

                Section("Tags") {
                    Text("No tags yet")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Organize")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New Project") {
                            // TODO: Show project creation sheet
                        }
                        Button("New Category") {
                            // TODO: Show category creation sheet
                        }
                        Button("New Tag") {
                            // TODO: Show tag creation sheet
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    OrganizeView()
        .modelContainer(for: Item.self, inMemory: true)
}
