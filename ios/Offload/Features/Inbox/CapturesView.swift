//
//  CapturesView.swift
//  Offload
//
//  Flat design captures list with inline tagging and swipe actions
//

import SwiftUI
import SwiftData

struct CapturesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(
        filter: #Predicate<Item> { $0.type == nil && $0.completedAt == nil },
        sort: \Item.createdAt,
        order: .reverse
    ) private var items: [Item]

    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var showingSettings = false
    @State private var selectedItem: Item?
    @State private var tagPickerItem: Item?
    @State private var moveItem: Item?
    @State private var moveDestination: MoveDestination?

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(items) { item in
                            ItemCard(
                                item: item,
                                colorScheme: colorScheme,
                                style: style,
                                onTap: { selectedItem = item },
                                onAddTag: { tagPickerItem = item },
                                onDelete: { deleteItem(item) },
                                onComplete: { completeItem(item) },
                                onMoveTo: { destination in
                                    moveItem = item
                                    moveDestination = destination
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            .navigationTitle("Captures")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: Icons.settings)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $selectedItem) { item in
                ItemEditView(item: item)
            }
            .sheet(item: $tagPickerItem) { item in
                TagPickerSheet(
                    item: item,
                    allTags: allTags,
                    colorScheme: colorScheme,
                    style: style,
                    onCreateTag: { name in
                        createTag(name: name, for: item)
                    },
                    onToggleTag: { tag in
                        toggleTag(tag, for: item)
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: .constant(moveItem != nil && moveDestination == .plan)) {
                if let item = moveItem {
                    MoveToPlanSheet(item: item, modelContext: modelContext) {
                        moveItem = nil
                        moveDestination = nil
                    }
                }
            }
            .sheet(isPresented: .constant(moveItem != nil && moveDestination == .list)) {
                if let item = moveItem {
                    MoveToListSheet(item: item, modelContext: modelContext) {
                        moveItem = nil
                        moveDestination = nil
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteItem(_ item: Item) {
        modelContext.delete(item)
    }

    private func completeItem(_ item: Item) {
        item.completedAt = Date()
    }

    private func createTag(name: String, for item: Item) {
        let tag = Tag(name: name)
        modelContext.insert(tag)
        if !item.tags.contains(name) {
            item.tags.append(name)
        }
    }

    private func toggleTag(_ tag: Tag, for item: Item) {
        if let index = item.tags.firstIndex(of: tag.name) {
            item.tags.remove(at: index)
        } else {
            item.tags.append(tag.name)
        }
    }
}

// MARK: - Move Destination

enum MoveDestination {
    case plan
    case list
}

// MARK: - Item Card

private struct ItemCard: View {
    let item: Item
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void
    let onMoveTo: (MoveDestination) -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Content
            Text(item.content)
                .font(.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

            // Tags and metadata
            HStack(spacing: Theme.Spacing.sm) {
                // Star indicator
                if item.isStarred {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.warning(colorScheme, style: style))
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

                Spacer()

                // Add tag button
                Button(action: onAddTag) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }

            // Creation date
            Text(item.createdAt, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.card(colorScheme, style: style))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            // Swipe indicators
            HStack {
                if offset > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.success(colorScheme, style: style))
                        .padding(.leading, Theme.Spacing.md)
                }

                Spacer()

                if offset < 0 {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(Theme.Colors.destructive(colorScheme, style: style))
                        .padding(.trailing, Theme.Spacing.md)
                }
            }
        )
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.width
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if value.translation.width > 100 {
                            offset = 0
                            onComplete()
                        } else if value.translation.width < -100 {
                            offset = 0
                            onDelete()
                        } else {
                            offset = 0
                        }
                    }
                }
        )
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button {
                onMoveTo(.plan)
            } label: {
                Label("Move to Plan", systemImage: Icons.plans)
            }

            Button {
                onMoveTo(.list)
            } label: {
                Label("Move to List", systemImage: Icons.lists)
            }
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: Tag
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var chipColor: Color {
        if let colorHex = tag.color {
            return Color(hex: colorHex)
        }
        return Theme.Colors.primary(colorScheme, style: style)
    }

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .foregroundStyle(chipColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(chipColor.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Tag Picker Sheet

private struct TagPickerSheet: View {
    let item: Item
    let allTags: [Tag]
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onCreateTag: (String) -> Void
    let onToggleTag: (Tag) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newTagName = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Create New Tag") {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                            .focused($focused)
                        Button("Add") {
                            onCreateTag(newTagName)
                            newTagName = ""
                        }
                        .disabled(newTagName.isEmpty)
                    }
                }

                Section("Select Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            onToggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if item.tags.contains(tag.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Item Edit View

private struct ItemEditView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var content: String

    init(item: Item) {
        self.item = item
        _content = State(initialValue: item.content)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.content = content
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Move to Plan Sheet

private struct MoveToPlanSheet: View {
    let item: Item
    let modelContext: ModelContext
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newPlanName = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !collections.isEmpty {
                    Section("Select Plan") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelectedPlan()
                            } label: {
                                Text(collection.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label("Create New Plan", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New Plan", isPresented: $createNew) {
                TextField("Plan name", text: $newPlanName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewPlanAndMove()
                }
            } message: {
                Text("Enter a name for the new plan")
            }
            .onAppear {
                loadCollections()
            }
        }
    }

    private func loadCollections() {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        collections = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func moveToSelectedPlan() {
        guard let collection = selectedCollection else { return }

        // Update item type
        item.type = "task"

        // Link to collection
        let position = collection.collectionItems?.count ?? 0
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: position
        )
        modelContext.insert(collectionItem)

        dismiss()
        onComplete()
    }

    private func createNewPlanAndMove() {
        let trimmed = newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Create collection
        let collection = Collection(name: trimmed, isStructured: true)
        modelContext.insert(collection)

        // Update item type
        item.type = "task"

        // Link to collection
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: 0
        )
        modelContext.insert(collectionItem)

        dismiss()
        onComplete()
    }
}

// MARK: - Move to List Sheet

private struct MoveToListSheet: View {
    let item: Item
    let modelContext: ModelContext
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newListName = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !collections.isEmpty {
                    Section("Select List") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelectedList()
                            } label: {
                                Text(collection.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label("Create New List", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New List", isPresented: $createNew) {
                TextField("List name", text: $newListName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewListAndMove()
                }
            } message: {
                Text("Enter a name for the new list")
            }
            .onAppear {
                loadCollections()
            }
        }
    }

    private func loadCollections() {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        collections = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func moveToSelectedList() {
        guard let collection = selectedCollection else { return }

        // Update item type
        item.type = "note"

        // Link to collection (no position for unstructured lists)
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: nil
        )
        modelContext.insert(collectionItem)

        dismiss()
        onComplete()
    }

    private func createNewListAndMove() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Create collection
        let collection = Collection(name: trimmed, isStructured: false)
        modelContext.insert(collection)

        // Update item type
        item.type = "note"

        // Link to collection
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: nil
        )
        modelContext.insert(collectionItem)

        dismiss()
        onComplete()
    }
}

#Preview {
    CapturesView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
