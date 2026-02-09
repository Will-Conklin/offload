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

// MARK: - Hierarchical Item Row (for Plans)

private struct HierarchicalItemRow: View {
    let item: Item
    let collectionItem: CollectionItem
    let isExpanded: Bool
    let hasChildren: Bool
    let showChevronSpace: Bool
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onAddTag: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onOpenLink: (UUID) -> Void
    let onError: (Error) -> Void
    let onDrop: (UUID, UUID, Bool) -> Void
    let onToggleExpand: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.collectionItemRepository) private var collectionItemRepository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingMenu = false
    @State private var linkedCollectionName: String?
    @State private var isDropTarget = false
    @State private var nestingLevel: Int = 0

    private var isLink: Bool {
        item.itemType == .link
    }

    private var indentation: CGFloat {
        CGFloat(nestingLevel) * Theme.Spacing.xl
    }

    var body: some View {
        HStack(spacing: 0) {
            // Indentation for nested items
            if nestingLevel > 0 {
                Color.clear
                    .frame(width: indentation)

                // Visual indicator for nesting
                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.3))
                    .frame(width: 2)
                    .padding(.trailing, Theme.Spacing.sm)
            }

            // Expand/collapse button for parent items (or spacer for consistency)
            if showChevronSpace {
                Button {
                    if hasChildren {
                        onToggleExpand()
                    }
                } label: {
                    if hasChildren {
                        AppIcon(
                            name: isExpanded ? Icons.chevronDown : Icons.chevronRight,
                            size: 16
                        )
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 44, height: 44)
                .buttonStyle(.plain)
                .disabled(!hasChildren)
                .padding(.trailing, Theme.Spacing.xs)
            }

            ItemRow(
                item: item,
                collectionItem: collectionItem,
                isStructured: true,
                colorScheme: colorScheme,
                style: style,
                onAddTag: onAddTag,
                onDelete: onDelete,
                onEdit: onEdit,
                onOpenLink: onOpenLink,
                onError: onError
            )
            .draggable(collectionItem.id.uuidString) {
                // Preview while dragging - simple view without environment objects
                Text(item.content)
                    .font(Theme.Typography.caption)
                    .lineLimit(2)
                    .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                    .padding(Theme.Spacing.sm)
                    .frame(width: 200)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                            .fill(Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style))
                    )
            }
            .dropDestination(for: String.self) { droppedIds, _ in
                guard let droppedIdString = droppedIds.first,
                      let droppedId = UUID(uuidString: droppedIdString)
                else {
                    return false
                }

                // Prevent dropping on self
                if droppedId == collectionItem.id {
                    return false
                }

                // Determine if this is a nesting drop (center) or reorder drop (edge)
                // For now, always reorder (nesting can be added with long-press in future)
                onDrop(droppedId, collectionItem.id, false)
                return true
            } isTargeted: { isTargeted in
                withAnimation(reduceMotion ? .default : .easeInOut(duration: 0.2)) {
                    isDropTarget = isTargeted
                }
            }
            .overlay(alignment: .top) {
                // Show insertion line between cards when dropping
                if isDropTarget {
                    Rectangle()
                        .fill(Theme.Colors.primary(colorScheme, style: style))
                        .frame(height: 3)
                        .offset(y: -(Theme.Spacing.md / 2 + 1.5)) // Center in the gap between cards
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? .default : .easeInOut(duration: 0.2), value: isDropTarget)
        }
        .accessibilityAction(named: "Move up") {
            onMoveUp?()
        }
        .accessibilityAction(named: "Move down") {
            onMoveDown?()
        }
        .onAppear {
            calculateNestingLevel()
        }
    }

    private func calculateNestingLevel() {
        var level = 0
        var currentParentId = collectionItem.parentId

        // Log if item has a parentId
        if let parentId = currentParentId {
            AppLogger.general.debug("Item \(collectionItem.id) has parentId: \(parentId)")
        }

        while let parentId = currentParentId, level < 10 { // Max depth of 10 to prevent infinite loops
            level += 1
            do {
                if let parent = try collectionItemRepository.fetchById(parentId) {
                    currentParentId = parent.parentId
                } else {
                    AppLogger.general.warning("Parent \(parentId) not found, breaking nesting calculation")
                    break
                }
            } catch {
                AppLogger.general.error("Error fetching parent: \(error.localizedDescription)")
                onError(error)
                break
            }
        }

        if level > 0 {
            AppLogger.general.debug("Item \(collectionItem.id) calculated nesting level: \(level)")
        }
        nestingLevel = level
    }
}

// MARK: - Bottom Drop Zone

private struct BottomDropZone: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onDrop: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
            .fill(isDropTarget
                ? Theme.Colors.primary(colorScheme, style: style).opacity(0.08)
                : Color.white.opacity(0.001) // Nearly invisible but receives hit tests
            )
            .frame(height: isDropTarget ? 60 : 44)
            .overlay {
                if isDropTarget {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .strokeBorder(
                            Theme.Colors.primary(colorScheme, style: style),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                        )
                }
            }
            .dropDestination(for: String.self) { droppedIds, _ in
                guard let droppedIdString = droppedIds.first,
                      let droppedId = UUID(uuidString: droppedIdString)
                else {
                    return false
                }

                onDrop(droppedId)
                return true
            } isTargeted: { isTargeted in
                withAnimation(reduceMotion ? .default : .easeInOut(duration: 0.2)) {
                    isDropTarget = isTargeted
                }
            }
    }
}

// MARK: - Draggable Item Row (for Lists)

private struct DraggableItemRow: View {
    let item: Item
    let collectionItem: CollectionItem
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onAddTag: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onOpenLink: (UUID) -> Void
    let onError: (Error) -> Void
    let onDrop: (UUID, UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        ItemRow(
            item: item,
            collectionItem: collectionItem,
            isStructured: false,
            colorScheme: colorScheme,
            style: style,
            onAddTag: onAddTag,
            onDelete: onDelete,
            onEdit: onEdit,
            onOpenLink: onOpenLink,
            onError: onError
        )
        .draggable(collectionItem.id.uuidString) {
            // Preview while dragging - simple view without environment objects
            Text(item.content)
                .font(Theme.Typography.caption)
                .lineLimit(2)
                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                .padding(Theme.Spacing.sm)
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style))
                )
        }
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let droppedIdString = droppedIds.first,
                  let droppedId = UUID(uuidString: droppedIdString)
            else {
                return false
            }

            // Prevent dropping on self
            if droppedId == collectionItem.id {
                return false
            }

            // Handle the drop
            onDrop(droppedId, collectionItem.id)
            return true
        } isTargeted: { isTargeted in
            withAnimation(reduceMotion ? .default : .easeInOut(duration: 0.2)) {
                isDropTarget = isTargeted
            }
        }
        .overlay(alignment: .top) {
            // Show insertion line between cards when dropping
            if isDropTarget {
                Rectangle()
                    .fill(Theme.Colors.primary(colorScheme, style: style))
                    .frame(height: 3)
                    .offset(y: -(Theme.Spacing.md / 2 + 1.5)) // Center in the gap between cards
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .default : .easeInOut(duration: 0.2), value: isDropTarget)
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    let item: Item
    let collectionItem: CollectionItem
    let isStructured: Bool
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onAddTag: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onOpenLink: (UUID) -> Void
    let onError: (Error) -> Void

    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @State private var showingMenu = false
    @State private var linkedCollectionName: String?

    private var isLink: Bool {
        item.itemType == .link
    }

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
            MCMCardContent(
                icon: item.itemType?.icon,
                title: displayTitle,
                typeLabel: item.type?.uppercased(),
                timestamp: item.relativeTimestamp,
                image: item.attachmentData.flatMap { UIImage(data: $0) },
                tags: item.tags,
                onAddTag: onAddTag,
                size: .compact // Compact size for item cards
            )
        }
        .overlay(alignment: .bottomTrailing) {
            StarButton(isStarred: item.isStarred, action: toggleStar)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showingMenu = true
            } label: {
                IconTile(
                    iconName: Icons.more,
                    iconSize: 16,
                    tileSize: 44,
                    style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                )
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.md)
            .accessibilityLabel("Item actions")
            .accessibilityHint("Show options for this item.")
            .confirmationDialog("Item Actions", isPresented: $showingMenu) {
                Button("Remove from Collection", role: .destructive) {
                    onDelete()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            handleTap()
        }
        .onAppear {
            loadLinkedCollectionName()
        }
        .onChange(of: item.linkedCollectionId) { _, _ in
            loadLinkedCollectionName()
        }
    }

    private var displayTitle: String {
        if isLink, let linkedCollectionName {
            return linkedCollectionName
        }
        if isLink, item.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Linked Collection"
        }
        return item.content
    }

    private func toggleStar() {
        do {
            try itemRepository.toggleStar(item)
        } catch {
            onError(error)
        }
    }

    private func handleTap() {
        if isLink, let linkedId = item.linkedCollectionId {
            onOpenLink(linkedId)
        } else {
            onEdit()
        }
    }

    private func loadLinkedCollectionName() {
        guard let linkedId = item.linkedCollectionId else {
            linkedCollectionName = nil
            return
        }
        do {
            linkedCollectionName = try collectionRepository.fetchById(linkedId)?.name
        } catch {
            linkedCollectionName = nil
            onError(error)
        }
    }
}

// MARK: - Item Edit Sheet

private struct ItemEditSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @State private var errorPresenter = ErrorPresenter()
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
                        .frame(minHeight: 120)
                }

                if let attachmentData = item.attachmentData,
                   let uiImage = UIImage(data: attachmentData)
                {
                    Section("Attachment") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try itemRepository.updateContent(
                                item,
                                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            dismiss()
                        } catch {
                            errorPresenter.present(error)
                        }
                    }
                }
            }
        }
        .errorToasts(errorPresenter)
    }
}

// MARK: - Add Item Sheet

private struct AddItemSheet: View {
    let collectionID: UUID
    let collection: Collection?

    @Query(sort: \Collection.name) private var collections: [Collection]
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var content = ""
    @State private var type: ItemType = .task
    @State private var isStarred = false
    @State private var selectedTags: [Tag] = []
    @State private var linkedCollectionId: UUID?
    @State private var attachmentData: Data?
    @State private var showingTags = false
    @State private var voiceService = VoiceRecordingService()
    @State private var preRecordingText = ""
    @State private var showingPermissionAlert = false
    @State private var showingAttachmentSource = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingCameraUnavailableAlert = false
    @State private var errorPresenter = ErrorPresenter()

    @FocusState private var isFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    private var linkableCollections: [Collection] {
        collections.filter { $0.id != collectionID && !$0.isStructured }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputSection
                Spacer()
                bottomBar
            }
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTags) {
                TagSelectionSheet(selectedTags: $selectedTags)
                    .environmentObject(themeManager)
                    .presentationDetents([.medium])
            }
            .confirmationDialog("Add Attachment", isPresented: $showingAttachmentSource) {
                Button("Camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    } else {
                        showingCameraUnavailableAlert = true
                    }
                }
                Button("Photo Library") {
                    imagePickerSource = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imagePickerSource, imageData: $attachmentData)
            }
            .alert("Mic Permission Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device does not support camera capture.")
            }
            .onChange(of: voiceService.transcribedText) { _, newValue in
                guard type != .link, !newValue.isEmpty else { return }
                let sep = preRecordingText.isEmpty || preRecordingText.hasSuffix(" ") ? "" : " "
                content = preRecordingText + sep + newValue
            }
            .onAppear {
                isFocused = true
                if type == .link {
                    if linkedCollectionId == nil || linkedCollectionId == collectionID {
                        linkedCollectionId = linkableCollections.first?.id
                    }
                }
            }
            .onChange(of: type) { _, newValue in
                if newValue == .link {
                    if voiceService.isRecording {
                        voiceService.stopRecording()
                    }
                    linkedCollectionId = linkableCollections.first?.id
                } else {
                    linkedCollectionId = nil
                }
            }
        }
        .errorToasts(errorPresenter)
    }

    private var inputSection: some View {
        InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Picker("Type", selection: $type) {
                    ForEach(ItemType.allCases, id: \.self) { itemType in
                        Text(itemType.displayName).tag(itemType)
                    }
                }
                .pickerStyle(.segmented)

                if type == .link {
                    linkPicker
                } else {
                    TextEditor(text: $content)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                        .frame(minHeight: 100)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty, !isFocused {
                                Text("Add details...")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface(colorScheme, style: style))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                                .stroke(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.35), lineWidth: 0.6)
                        )

                    if voiceService.isRecording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.Colors.destructive(colorScheme, style: style))
                                .frame(width: 8, height: 8)
                            Text(formatDuration(voiceService.recordingDuration))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                        }
                    }

                    if let attachmentData, let uiImage = UIImage(data: attachmentData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))

                            Button {
                                self.attachmentData = nil
                            } label: {
                                IconTile(
                                    iconName: Icons.closeCircleFilled,
                                    iconSize: 16,
                                    tileSize: 44,
                                    style: .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                                )
                                .shadow(color: Theme.Shadows.ultraLight(colorScheme), radius: Theme.Shadows.elevationUltraLight, y: Theme.Shadows.offsetYUltraLight)
                            }
                            .padding(4)
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove attachment")
                        }
                    }
                }

                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(selectedTags) { tag in
                                TagPill(
                                    name: tag.name,
                                    color: Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var linkPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Linked List")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

            if linkableCollections.isEmpty {
                Text("No lists available.")
                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
            } else {
                Picker("List", selection: $linkedCollectionId) {
                    ForEach(linkableCollections) { collection in
                        Text(collection.name).tag(Optional(collection.id))
                    }
                }
                .pickerStyle(.menu)
                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
            }
        }
    }

    private var bottomBar: some View {
        ActionBarContainer(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
            HStack(spacing: Theme.Spacing.md) {
                if type != .link {
                    Button(action: handleVoice) {
                        IconTile(
                            iconName: voiceService.isRecording ? Icons.stopFilled : Icons.microphone,
                            iconSize: 20,
                            tileSize: 44,
                            style: voiceService.isRecording
                                ? .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                                : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(voiceService.isRecording ? "Stop recording" : "Start voice capture")
                    .accessibilityHint(
                        voiceService.isRecording
                            ? "Stops recording and keeps the transcription."
                            : "Records voice and transcribes into the item."
                    )

                    Button { showingAttachmentSource = true } label: {
                        IconTile(
                            iconName: attachmentData != nil ? Icons.cameraFilled : Icons.camera,
                            iconSize: 20,
                            tileSize: 44,
                            style: attachmentData != nil
                                ? .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                                : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(attachmentData == nil ? "Add attachment" : "Change attachment")
                    .accessibilityHint("Attach a photo to this item.")
                }

                Button { showingTags = true } label: {
                    IconTile(
                        iconName: selectedTags.isEmpty ? Icons.tag : Icons.tagFilled,
                        iconSize: 20,
                        tileSize: 44,
                        style: selectedTags.isEmpty
                            ? .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                            : .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectedTags.isEmpty ? "Add tags" : "Edit tags")
                .accessibilityHint("Select tags for this item.")

                Button { isStarred.toggle() } label: {
                    IconTile(
                        iconName: isStarred ? Icons.starFilled : Icons.star,
                        iconSize: 20,
                        tileSize: 44,
                        style: isStarred
                            ? .primaryFilled(Theme.Colors.caution(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isStarred ? "Unstar item" : "Star item")
                .accessibilityHint("Toggle the star for this item.")

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.buttonDark(colorScheme))
                        .clipShape(Capsule())
                        .shadow(
                            color: Theme.Shadows.ultraLight(colorScheme),
                            radius: Theme.Shadows.elevationUltraLight,
                            y: Theme.Shadows.offsetYUltraLight
                        )
                }
                .disabled(isAddDisabled)
                .opacity(isAddDisabled ? 0.5 : 1)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    private func handleVoice() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            preRecordingText = content
            _Concurrency.Task {
                do { try await voiceService.startRecording() } catch { showingPermissionAlert = true }
            }
        }
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }

    private var isAddDisabled: Bool {
        if type == .link {
            return linkedCollectionId == nil || linkedCollectionId == collectionID
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        if voiceService.isRecording { voiceService.stopRecording() }
        do {
            try addItem()
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func addItem() throws {
        let linkedId = type == .link ? linkedCollectionId : nil
        let linkedName = linkableCollections.first { $0.id == linkedId }?.name
        if type == .link {
            guard let linkedId else {
                throw ValidationError("Select a list to link.")
            }
            if linkedId == collectionID {
                throw ValidationError("Linked list cannot match this collection.")
            }
        } else {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw ValidationError("Item content cannot be empty.")
            }
        }

        let resolvedContent = type == .link ? (linkedName ?? "Linked Collection") : content
        let trimmedContent = resolvedContent.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = try itemRepository.create(
            type: type.rawValue,
            content: trimmedContent,
            attachmentData: attachmentData,
            linkedCollectionId: linkedId,
            tags: selectedTags,
            isStarred: isStarred
        )

        let targetCollection: Collection
        if let collection {
            targetCollection = collection
        } else if let fetched = try collectionRepository.fetchById(collectionID) {
            targetCollection = fetched
        } else {
            throw ValidationError("Collection not found.")
        }

        let position = targetCollection.isStructured ? (targetCollection.collectionItems?.count ?? 0) : nil
        try itemRepository.moveToCollection(item, collection: targetCollection, position: position)
    }
}

// MARK: - Edit Collection Sheet

private struct EditCollectionSheet: View {
    let collection: Collection

    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var errorPresenter = ErrorPresenter()

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
                        do {
                            try collectionRepository.delete(collection)
                            dismiss()
                        } catch {
                            errorPresenter.present(error)
                        }
                    }
                }
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try collectionRepository.updateName(
                                collection,
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            dismiss()
                        } catch {
                            errorPresenter.present(error)
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .errorToasts(errorPresenter)
    }
}

#Preview {
    CollectionDetailView(collectionID: UUID())
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
