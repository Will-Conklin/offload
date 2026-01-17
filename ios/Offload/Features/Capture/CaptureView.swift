//
//  CaptureView.swift
//  Offload
//
//  Flat design capture list with inline tagging and swipe actions
//

import SwiftUI
import SwiftData
import UIKit

// AGENT NAV
// - State
// - Layout
// - Actions
// - Item Card
// - Tag Picker

struct CaptureView: View {
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
    @State private var showingAccount = false
    @State private var showingAddItem = false
    @State private var selectedItem: Item?
    @State private var tagPickerItem: Item?
    @State private var moveItem: Item?
    @State private var moveDestination: MoveDestination?

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }
    private var tagLookup: [String: Tag] {
        Dictionary(uniqueKeysWithValues: allTags.map { ($0.name, $0) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            ItemCard(
                                index: index,
                                item: item,
                                colorScheme: colorScheme,
                                style: style,
                                tagLookup: tagLookup,
                                onTap: { selectedItem = item },
                                onAddTag: { tagPickerItem = item },
                                onToggleStar: { toggleStar(item) },
                                onDelete: { deleteItem(item) },
                                onComplete: { completeItem(item) },
                                onMoveTo: { destination in
                                    moveItem = item
                                    moveDestination = destination
                                }
                            )
                        }

                        FloatingActionButton(title: "Add Item", iconName: Icons.addCircleFilled) {
                            showingAddItem = true
                        }
                        .accessibilityLabel("Add Item")
                        .padding(.top, Theme.Spacing.sm)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: floatingTabBarClearance)
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAccount = true
                    } label: {
                        IconTile(
                            iconName: Icons.account,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Account")

                    Button {
                        showingSettings = true
                    } label: {
                        IconTile(
                            iconName: Icons.settings,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAccount) {
                AccountView()
            }
            .sheet(isPresented: $showingAddItem) {
                CaptureComposeView()
            }
            .sheet(item: $selectedItem) { item in
                CaptureDetailView(item: item)
            }
            .sheet(item: $tagPickerItem) { item in
                ItemTagPickerSheet(item: item)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented:
                Binding(
                    get: { moveItem != nil && moveDestination == .plan },
                    set: { presented in
                        if !presented {
                            moveItem = nil
                            moveDestination = nil
                        }
                    }
                )
            ) {
                if let item = moveItem {
                    MoveToPlanSheet(item: item, modelContext: modelContext) {
                        moveItem = nil
                        moveDestination = nil
                    }
                }
            }
            .sheet(isPresented:
                Binding(
                    get: { moveItem != nil && moveDestination == .list },
                    set: { presented in
                        if !presented {
                            moveItem = nil
                            moveDestination = nil
                        }
                    }
                )
            ) {
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

    private func toggleStar(_ item: Item) {
        item.isStarred.toggle()
    }
}

// MARK: - Move Destination

enum MoveDestination {
    case plan
    case list
}

// MARK: - Item Card

private struct ItemCard: View {
    let index: Int
    let item: Item
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let tagLookup: [String: Tag]
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onToggleStar: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void
    let onMoveTo: (MoveDestination) -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        Button(action: onTap) {
            CardSurface {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(item.content)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))

                    if let attachmentData = item.attachmentData,
                       let uiImage = UIImage(data: attachmentData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                    }

                    Text(item.createdAt, format: .relative(presentation: .named))
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

                    ItemActionRow(
                        tags: item.tags,
                        tagLookup: tagLookup,
                        isStarred: item.isStarred,
                        onAddTag: onAddTag,
                        onToggleStar: onToggleStar
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .cardButtonStyle()
        .overlay(
            // Swipe indicators
            HStack {
                if offset > 0 {
                    AppIcon(name: Icons.checkCircleFilled, size: 18)
                        .foregroundStyle(Theme.Colors.success(colorScheme, style: style))
                        .padding(.leading, Theme.Spacing.md)
                        .opacity(min(1, Double(offset / 120)))
                }

                Spacer()

                if offset < 0 {
                    AppIcon(name: Icons.deleteFilled, size: 18)
                        .foregroundStyle(Theme.Colors.destructive(colorScheme, style: style))
                        .padding(.trailing, Theme.Spacing.md)
                        .opacity(min(1, Double(-offset / 120)))
                }
            }
        )
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    offset = dx
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else {
                        offset = 0
                        return
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if dx > 100 {
                            offset = 0
                            onComplete()
                        } else if dx < -100 {
                            offset = 0
                            onDelete()
                        } else {
                            offset = 0
                        }
                    }
                }
        )
        .contextMenu {
            Button {
                onMoveTo(.plan)
            } label: {
                Label {
                    Text("Move to Plan")
                } icon: {
                    AppIcon(name: Icons.plans, size: 14)
                }
            }

            Button {
                onMoveTo(.list)
            } label: {
                Label {
                    Text("Move to List")
                } icon: {
                    AppIcon(name: Icons.lists, size: 14)
                }
            }
        }
    }
}

// MARK: - Item Edit View

private struct CaptureDetailView: View {
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
            .navigationTitle("Capture Detail")
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
                        Label {
                            Text("Create New Plan")
                        } icon: {
                            AppIcon(name: Icons.addCircleFilled, size: 16)
                        }
                                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to Plan")
            .navigationBarTitleDisplayMode(.large)
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
                        Label {
                            Text("Create New List")
                        } icon: {
                            AppIcon(name: Icons.addCircleFilled, size: 16)
                        }
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
        item.type = "task"

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
        item.type = "task"

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
    CaptureView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
