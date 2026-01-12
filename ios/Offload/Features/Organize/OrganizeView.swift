//
//  OrganizeView.swift
//  Offload
//
//  Simplified design for Plans and Lists tabs using Collections
//

import SwiftUI
import SwiftData

struct OrganizeView: View {
    enum Scope {
        case plans, lists

        var title: String {
            switch self {
            case .plans: return "Plans"
            case .lists: return "Lists"
            }
        }

        var isStructured: Bool {
            switch self {
            case .plans: return true
            case .lists: return false
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Collection.createdAt, order: .reverse) private var allCollections: [Collection]

    let scope: Scope
    @State private var showingCreate = false
    @State private var showingSettings = false
    @State private var selectedCollection: Collection?

    private var style: ThemeStyle { themeManager.currentStyle }

    private var filteredCollections: [Collection] {
        allCollections.filter { $0.isStructured == scope.isStructured }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        collectionsContent
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(scope.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: Icons.settings)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                createSheet
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(item: $selectedCollection) { collection in
                CollectionDetailView(collectionID: collection.id)
            }
        }
    }

    // MARK: - Collections Content

    @ViewBuilder
    private var collectionsContent: some View {
        if filteredCollections.isEmpty {
            emptyState
        } else {
            ForEach(filteredCollections) { collection in
                CollectionCard(collection: collection, colorScheme: colorScheme, style: style)
                    .onTapGesture { selectedCollection = collection }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: scope == .plans ? Icons.plans : Icons.lists)
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            Text("No \(scope.title.lowercased()) yet")
                .font(.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            Button("Create \(scope == .plans ? "Plan" : "List")") { showingCreate = true }
                .font(.headline)
                .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }

    // MARK: - Create Sheet

    @ViewBuilder
    private var createSheet: some View {
        CollectionFormSheet(isStructured: scope.isStructured) { name in
            let collection = Collection(name: name, isStructured: scope.isStructured)
            modelContext.insert(collection)
        }
    }
}

// MARK: - Collection Card

private struct CollectionCard: View {
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(collection.name)
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                Spacer()

                if collection.isStructured {
                    Image(systemName: "list.number")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            HStack {
                Text(collection.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                Spacer()

                if let count = collection.collectionItems?.count, count > 0 {
                    Text("\(count) item\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.card(colorScheme, style: style))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

// MARK: - Form Sheet

private struct CollectionFormSheet: View {
    let isStructured: Bool
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(isStructured ? "Plan name" : "List name", text: $name)
            }
            .navigationTitle(isStructured ? "New Plan" : "New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    OrganizeView(scope: .plans)
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
