// Purpose: Organize feature views and flows.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep collection ordering aligned with Collection.sortedItems and CollectionItem.position.

//  Unified detail view for both structured (plans) and unstructured (lists) collections

import OSLog
import SwiftData
import SwiftUI
import UIKit

struct CollectionDetailView: View {
    let collectionID: UUID

    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.collectionItemRepository) private var collectionItemRepository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collection: Collection?
    @State private var showingAddItem = false
    @State private var showingEdit = false
    @State private var linkedCollection: Collection?
    @State private var editingItem: Item?
    @State private var tagPickerItem: Item?
    @State private var errorPresenter = ErrorPresenter()
    @State private var viewModel = CollectionDetailViewModel()
    @State private var expandedItems: Set<UUID> = [] // Track which parent items are expanded

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }

    private var visiblePlanItems: [CollectionItem] {
        guard collection?.isStructured == true else { return viewModel.items }

        var visible: [CollectionItem] = []

        func addVisibleItems(parentId: UUID?) {
            let itemsAtLevel = viewModel.items.filter { $0.parentId == parentId }
            for item in itemsAtLevel {
                visible.append(item)
                // Only show children if parent is expanded
                if expandedItems.contains(item.id) {
                    addVisibleItems(parentId: item.id)
                }
            }
        }

        addVisibleItems(parentId: nil) // Start with root items
        return visible
    }

    private var planHasHierarchy: Bool {
        guard collection?.isStructured == true else { return false }
        return viewModel.items.contains { $0.parentId != nil }
    }

    var body: some View {
        ZStack {
            Theme.Colors.background(colorScheme, style: style)
                .ignoresSafeArea()

            if let collection {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        // Items list
                        if collection.isStructured {
                            // Structured collections (plans) - support drag-to-parent and reordering
                            LazyVStack(spacing: Theme.Spacing.md) {
                                if viewModel.items.isEmpty, viewModel.isLoading {
                                    ProgressView()
                                        .padding(.vertical, Theme.Spacing.sm)
                                }

                                ForEach(Array(visiblePlanItems.enumerated()), id: \.element.id) { index, collectionItem in
                                    if let item = collectionItem.item {
                                        HierarchicalItemRow(
                                            item: item,
                                            collectionItem: collectionItem,
                                            isExpanded: expandedItems.contains(collectionItem.id),
                                            hasChildren: collectionItem.hasChildren(in: collectionItemRepository.modelContext),
                                            showChevronSpace: planHasHierarchy,
                                            colorScheme: colorScheme,
                                            style: style,
                                            onAddTag: { tagPickerItem = item },
                                            onDelete: { deleteItem(collectionItem) },
                                            onEdit: { editingItem = item },
                                            onOpenLink: { openLinkedCollection($0) },
                                            onError: { errorPresenter.present($0) },
                                            onDrop: { droppedId, targetId, isNesting in
                                                handlePlanDrop(droppedId: droppedId, targetId: targetId, isNesting: isNesting)
                                            },
                                            onToggleExpand: {
                                                toggleExpanded(collectionItem.id)
                                            },
                                            onMoveUp: index > 0 ? {
                                                let targetId = visiblePlanItems[index - 1].id
                                                handlePlanDrop(droppedId: collectionItem.id, targetId: targetId, isNesting: false)
                                            } : nil,
                                            onMoveDown: index < visiblePlanItems.count - 1 ? {
                                                let targetId = visiblePlanItems[index + 1].id
                                                handlePlanDrop(droppedId: collectionItem.id, targetId: targetId, isNesting: false)
                                            } : nil
                                        )
                                        .onAppear {
                                            if index == visiblePlanItems.count - 1 {
                                                loadNextPage()
                                            }
                                        }
                                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                                    }
                                }

                                if viewModel.isLoading, !viewModel.items.isEmpty {
                                    ProgressView()
                                        .padding(.vertical, Theme.Spacing.sm)
                                }

                                if !viewModel.items.isEmpty {
                                    BottomDropZone(
                                        colorScheme: colorScheme,
                                        style: style,
                                        onDrop: { droppedId in
                                            handlePlanDropAtEnd(droppedId: droppedId)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .animation(reduceMotion ? .default : .spring(response: 0.3, dampingFraction: 0.8), value: visiblePlanItems.map(\.id))
                        } else {
                            // Unstructured collections (lists) - support basic reordering
                            LazyVStack(spacing: Theme.Spacing.md) {
                                if viewModel.items.isEmpty, viewModel.isLoading {
                                    ProgressView()
                                        .padding(.vertical, Theme.Spacing.sm)
                                }

                                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, collectionItem in
                                    if let item = collectionItem.item {
                                        DraggableItemRow(
                                            item: item,
                                            collectionItem: collectionItem,
                                            colorScheme: colorScheme,
                                            style: style,
                                            onAddTag: { tagPickerItem = item },
                                            onDelete: { deleteItem(collectionItem) },
                                            onEdit: { editingItem = item },
                                            onOpenLink: { openLinkedCollection($0) },
                                            onError: { errorPresenter.present($0) },
                                            onDrop: { droppedId, targetId in
                                                handleListReorder(droppedId: droppedId, targetId: targetId)
                                            }
                                        )
                                        .onAppear {
                                            if index == viewModel.items.count - 1 {
                                                loadNextPage()
                                            }
                                        }
                                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                                    }
                                }

                                if viewModel.isLoading, !viewModel.items.isEmpty {
                                    ProgressView()
                                        .padding(.vertical, Theme.Spacing.sm)
                                }

                                if !viewModel.items.isEmpty {
                                    BottomDropZone(
                                        colorScheme: colorScheme,
                                        style: style,
                                        onDrop: { droppedId in
                                            handleListDropAtEnd(droppedId: droppedId)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .animation(reduceMotion ? .default : .spring(response: 0.3, dampingFraction: 0.8), value: viewModel.items.map(\.id))
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: floatingTabBarClearance)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let collection {
                    VStack(spacing: 2) {
                        Text(collection.name)
                            .font(Theme.Typography.subheadlineSemibold)
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        Text(collection.isStructured ? "PLAN" : "LIST")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingAddItem = true } label: {
                    IconTile(
                        iconName: Icons.addCircleFilled,
                        iconSize: 18,
                        tileSize: 44,
                        style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                    )
                }
                .accessibilityLabel("Add item")

                Button { showingEdit = true } label: {
                    IconTile(
                        iconName: Icons.write,
                        iconSize: 18,
                        tileSize: 44,
                        style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .accessibilityLabel("Edit collection")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(collectionID: collectionID, collection: collection)
                .environmentObject(themeManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEdit) {
            if let collection {
                EditCollectionSheet(collection: collection)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditSheet(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $tagPickerItem) { item in
            ItemTagPickerSheet(item: item)
                .environmentObject(themeManager)
                .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $linkedCollection) { collection in
            CollectionDetailView(collectionID: collection.id)
                .environmentObject(themeManager)
        }
        .onChange(of: showingAddItem) { _, isPresented in
            if !isPresented {
                refreshItems()
            }
        }
        .onAppear {
            loadCollection()
        }
        .errorToasts(errorPresenter)
    }

    // MARK: - Data Loading

    private func loadCollection() {
        do {
            if let fetchedCollection = try collectionRepository.fetchById(collectionID) {
                // Backfill positions for any items missing them
                try collectionRepository.backfillPositions(fetchedCollection)

                collection = fetchedCollection
                try viewModel.setCollection(
                    id: fetchedCollection.id,
                    isStructured: fetchedCollection.isStructured,
                    using: collectionItemRepository
                )
            }
        } catch {
            errorPresenter.present(error)
        }
    }

    private func loadNextPage() {
        do {
            try viewModel.loadNextPage(using: collectionItemRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func refreshItems() {
        do {
            try viewModel.refresh(using: collectionItemRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func deleteItem(_ collectionItem: CollectionItem) {
        do {
            try collectionItemRepository.removeItemFromCollection(collectionItem)
            viewModel.remove(collectionItem)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func openLinkedCollection(_ collectionID: UUID) {
        do {
            linkedCollection = try collectionRepository.fetchById(collectionID)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func handleListReorder(droppedId: UUID, targetId: UUID) {
        guard let collection, !collection.isStructured else {
            AppLogger.general.warning("Attempted list reorder on structured collection, ignoring")
            return
        }

        AppLogger.general.info("List reorder: \(droppedId) to position of \(targetId)")

        do {
            // Find the dropped and target items in the list
            guard let droppedIndex = viewModel.items.firstIndex(where: { $0.id == droppedId }),
                  let targetIndex = viewModel.items.firstIndex(where: { $0.id == targetId })
            else {
                AppLogger.general.error("Could not find dropped or target item in list")
                return
            }

            // Reorder in view model
            let droppedItem = viewModel.items[droppedIndex]
            var newItems = viewModel.items
            newItems.remove(at: droppedIndex)

            // Adjust target index if item was removed before target position
            let adjustedTargetIndex = droppedIndex < targetIndex ? targetIndex - 1 : targetIndex
            newItems.insert(droppedItem, at: adjustedTargetIndex)

            // Update all positions and clear parent relationships (flat hierarchy)
            for (index, item) in newItems.enumerated() {
                item.position = index
                item.parentId = nil // Clear any parent relationship for flat ordering
            }

            try collectionItemRepository.modelContext.save()
            AppLogger.general.info("List items reordered successfully")

            // Refresh to show new order
            refreshItems()
        } catch {
            AppLogger.general.error("Failed to handle list reorder: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }

    private func handleListDropAtEnd(droppedId: UUID) {
        guard let collection, !collection.isStructured else {
            AppLogger.general.warning("Attempted list drop at end on structured collection, ignoring")
            return
        }

        AppLogger.general.info("List drop at end: \(droppedId)")

        do {
            guard let droppedItem = viewModel.items.first(where: { $0.id == droppedId }) else {
                AppLogger.general.error("Could not find dropped item in list")
                return
            }

            // Remove from current position
            var newItems = viewModel.items.filter { $0.id != droppedId }
            // Add to end
            newItems.append(droppedItem)

            // Update all positions and clear parent relationships (flat hierarchy)
            for (index, item) in newItems.enumerated() {
                item.position = index
                item.parentId = nil
            }

            try collectionItemRepository.modelContext.save()
            AppLogger.general.info("List item moved to end successfully")

            // Refresh to show new order
            refreshItems()
        } catch {
            AppLogger.general.error("Failed to handle list drop at end: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }

    private func handlePlanDrop(droppedId: UUID, targetId: UUID, isNesting: Bool) {
        guard let collection, collection.isStructured else {
            AppLogger.general.warning("Attempted plan drop on unstructured collection, ignoring")
            return
        }

        AppLogger.general.info("Plan drop: \(droppedId) onto \(targetId), nesting: \(isNesting)")

        do {
            guard let droppedItem = viewModel.items.first(where: { $0.id == droppedId }),
                  let targetItem = viewModel.items.first(where: { $0.id == targetId })
            else {
                AppLogger.general.error("Could not find dropped or target item")
                return
            }

            // Prevent nesting into self or descendants
            if isNesting, wouldCreateCycle(droppedId: droppedId, targetId: targetId) {
                AppLogger.general.warning("Cannot nest item into itself or its descendants")
                return
            }

            if isNesting {
                // Nest as child of target
                droppedItem.parentId = targetId

                // Find position as last child of target
                let targetChildren = viewModel.items.filter { $0.parentId == targetId }
                droppedItem.position = targetChildren.count

                // Expand the target to show the new child
                expandedItems.insert(targetId)

                AppLogger.general.info("Nested item \(droppedId) under \(targetId)")
            } else {
                // Reorder at same level as target (sibling)
                let targetParentId = targetItem.parentId
                droppedItem.parentId = targetParentId

                // Get all siblings at this level
                let siblings = viewModel.items.filter { $0.parentId == targetParentId }
                    .sorted { ($0.position ?? 0) < ($1.position ?? 0) }

                // Find target position
                guard let targetIndex = siblings.firstIndex(where: { $0.id == targetId }) else {
                    AppLogger.general.error("Could not find target in siblings")
                    return
                }

                // Check if dropped item was already in this sibling list
                let droppedIndex = siblings.firstIndex(where: { $0.id == droppedId })

                // Reorder siblings
                var reordered = siblings.filter { $0.id != droppedId }

                // Adjust target index if the dropped item was removed before target position
                var adjustedTargetIndex = targetIndex
                if let droppedIndex, droppedIndex < targetIndex {
                    adjustedTargetIndex = targetIndex - 1
                }

                reordered.insert(droppedItem, at: adjustedTargetIndex)

                // Update positions for all siblings
                for (index, sibling) in reordered.enumerated() {
                    sibling.position = index
                }

                AppLogger.general.info("Reordered item \(droppedId) to position \(targetIndex) at level \(targetParentId?.uuidString ?? "root")")
            }

            try collectionItemRepository.modelContext.save()

            // Refresh to show new order
            refreshItems()
        } catch {
            AppLogger.general.error("Failed to handle plan drop: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }

    private func handlePlanDropAtEnd(droppedId: UUID) {
        guard let collection, collection.isStructured else {
            AppLogger.general.warning("Attempted plan drop at end on unstructured collection, ignoring")
            return
        }

        AppLogger.general.info("Plan drop at end: \(droppedId)")

        do {
            guard let droppedItem = viewModel.items.first(where: { $0.id == droppedId }) else {
                AppLogger.general.error("Could not find dropped item")
                return
            }

            // Move to root level at the end
            droppedItem.parentId = nil

            // Get all root-level siblings
            let rootItems = viewModel.items.filter { $0.parentId == nil }
                .sorted { ($0.position ?? 0) < ($1.position ?? 0) }

            // Remove dropped item from list if already at root
            let reordered = rootItems.filter { $0.id != droppedId }

            // Update positions for all root items, placing dropped at end
            for (index, item) in reordered.enumerated() {
                item.position = index
            }
            droppedItem.position = reordered.count

            try collectionItemRepository.modelContext.save()
            AppLogger.general.info("Plan item moved to end at root level")

            // Refresh to show new order
            refreshItems()
        } catch {
            AppLogger.general.error("Failed to handle plan drop at end: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }

    private func wouldCreateCycle(droppedId: UUID, targetId: UUID) -> Bool {
        // Check if target is a descendant of dropped item
        var currentId: UUID? = targetId
        while let checkId = currentId {
            if checkId == droppedId {
                return true
            }
            currentId = viewModel.items.first(where: { $0.id == checkId })?.parentId
        }
        return false
    }

    private func toggleExpanded(_ itemId: UUID) {
        if expandedItems.contains(itemId) {
            expandedItems.remove(itemId)
        } else {
            expandedItems.insert(itemId)
        }
    }
}

#Preview {
    CollectionDetailView(collectionID: UUID())
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
