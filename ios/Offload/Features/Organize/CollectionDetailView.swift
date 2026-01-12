//
//  CollectionDetailView.swift
//  Offload
//
//  Unified detail view for both structured (plans) and unstructured (lists) collections
//

import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    let collectionID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collection: Collection?
    @State private var items: [CollectionItem] = []
    @State private var showingAddItem = false
    @State private var showingEdit = false
    @State private var newItemContent = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        ZStack {
            Theme.Colors.background(colorScheme, style: style)
                .ignoresSafeArea()

            if let collection = collection {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        // Collection header
                        collectionHeader(collection)

                        // Items list
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(items) { collectionItem in
                                if let item = collectionItem.item {
                                    ItemRow(
                                        item: item,
                                        collectionItem: collectionItem,
                                        isStructured: collection.isStructured,
                                        colorScheme: colorScheme,
                                        style: style,
                                        onDelete: { deleteItem(collectionItem) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, 100)
                }

                // Quick add button
                VStack {
                    Spacer()
                    quickAddButton
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEdit = true } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(collectionID: collectionID, collection: collection)
        }
        .sheet(isPresented: $showingEdit) {
            if let collection = collection {
                EditCollectionSheet(collection: collection)
            }
        }
        .onAppear {
            loadCollection()
        }
    }

    // MARK: - Collection Header

    private func collectionHeader(_ collection: Collection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(collection.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                Spacer()

                if collection.isStructured {
                    Image(systemName: "list.number")
                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                }
            }

            Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button {
            showingAddItem = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Item")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.primary(colorScheme, style: style))
            .clipShape(Capsule())
            .shadow(radius: 4)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Data Loading

    private func loadCollection() {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.id == collectionID }
        )
        if let fetchedCollection = try? modelContext.fetch(descriptor).first {
            self.collection = fetchedCollection
            loadItems()
        }
    }

    private func loadItems() {
        guard let collection = collection else { return }
        self.items = collection.sortedItems
    }

    private func deleteItem(_ collectionItem: CollectionItem) {
        modelContext.delete(collectionItem)
        try? modelContext.save()
        loadItems()
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    let item: Item
    let collectionItem: CollectionItem
    let isStructured: Bool
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showingMenu = false

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Position indicator for structured collections
            if isStructured, let position = collectionItem.position {
                Text("\(position + 1).")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    .frame(width: 30, alignment: .trailing)
            }

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(item.content)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                HStack(spacing: Theme.Spacing.sm) {
                    // Type indicator
                    if let type = item.type {
                        Text(type.capitalized)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                            .clipShape(Capsule())
                    }

                    // Tags
                    ForEach(item.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.border(colorScheme, style: style))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: Theme.Spacing.xs) {
                // Add tag button
                Button {
                    // TODO: Show tag picker
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .frame(width: 28, height: 28)
                }

                // Star button
                Button {
                    toggleStar()
                } label: {
                    Image(systemName: item.isStarred ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(item.isStarred ? Theme.Colors.warning(colorScheme, style: style) : Theme.Colors.textSecondary(colorScheme, style: style))
                        .frame(width: 28, height: 28)
                }

                // Actions menu
                Button {
                    showingMenu = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .frame(width: 28, height: 28)
                }
                .confirmationDialog("Item Actions", isPresented: $showingMenu) {
                    Button("Remove from Collection", role: .destructive) {
                        onDelete()
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.card(colorScheme, style: style))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }

    private func toggleStar() {
        item.isStarred.toggle()
        try? modelContext.save()
    }
}

// MARK: - Add Item Sheet

private struct AddItemSheet: View {
    let collectionID: UUID
    let collection: Collection?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var type: ItemType = .task
    @State private var isStarred = false
    @State private var tags: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Item content", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ItemType.allCases, id: \.self) { itemType in
                            Text(itemType.displayName).tag(itemType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Options") {
                    Toggle("Starred", isOn: $isStarred)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addItem() {
        // Create item
        let item = Item(
            type: type.rawValue,
            content: content,
            isStarred: isStarred,
            tags: tags
        )
        modelContext.insert(item)

        // Get next position for structured collections
        var position: Int? = nil
        if let collection = collection, collection.isStructured {
            position = collection.collectionItems?.count ?? 0
        }

        // Link to collection
        let collectionItem = CollectionItem(
            collectionId: collectionID,
            itemId: item.id,
            position: position
        )
        modelContext.insert(collectionItem)

        try? modelContext.save()
    }
}

// MARK: - Edit Collection Sheet

private struct EditCollectionSheet: View {
    let collection: Collection

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    init(collection: Collection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Collection name", text: $name)
                }

                Section {
                    Button("Delete Collection", role: .destructive) {
                        modelContext.delete(collection)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        collection.name = name
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CollectionDetailView(collectionID: UUID())
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
