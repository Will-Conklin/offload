//
//  OrganizeView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

struct OrganizeView: View {
    @Query private var plans: [Plan]
    @Query private var categories: [Category]
    @Query private var tags: [Tag]

    var body: some View {
        NavigationStack {
            List {
                // TODO: Implement plan/category sections
                Section("Plans") {
                    if plans.isEmpty {
                        Text("No plans yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(plans) { plan in
                            Text(plan.title)
                        }
                    }
                }

                Section("Categories") {
                    if categories.isEmpty {
                        Text("No categories yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { category in
                            Text(category.name)
                        }
                    }
                }

                Section("Tags") {
                    if tags.isEmpty {
                        Text("No tags yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tags) { tag in
                            Text(tag.name)
                        }
                    }
                }
            }
            .navigationTitle("Organize")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New Plan") {
                            // TODO: Show plan creation sheet
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
        .modelContainer(PersistenceController.preview)
}
