// Purpose: Item row views for CollectionDetailView.
// Authority: Code-level
// Governed by: AGENTS.md

import OSLog
import SwiftUI
import UIKit

// MARK: - Hierarchical Item Row (for Plans)

struct HierarchicalItemRow: View {
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
                withAnimation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion)) {
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
            .animation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion), value: isDropTarget)
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

struct BottomDropZone: View {
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
                withAnimation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion)) {
                    isDropTarget = isTargeted
                }
            }
    }
}

// MARK: - Draggable Item Row (for Lists)

struct DraggableItemRow: View {
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
            withAnimation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion)) {
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
        .animation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion), value: isDropTarget)
    }
}

// MARK: - Item Row

struct ItemRow: View {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingMenu = false
    @State private var linkedCollectionName: String?
    @State private var offset: CGFloat = 0

    private var isLink: Bool {
        item.itemType == .link
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete indicator (shown when swiping left)
            if offset < 0 {
                HStack {
                    Spacer()
                    AppIcon(name: Icons.deleteFilled, size: 24)
                        .foregroundStyle(Theme.Colors.destructive(colorScheme, style: style))
                        .padding(.trailing, Theme.Spacing.md)
                        .opacity(min(1, Double(-offset / 120)))
                }
            }

            CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
                MCMCardContent(
                    icon: item.itemType?.icon,
                    title: displayTitle,
                    typeLabel: item.type?.uppercased(),
                    timestamp: item.relativeTimestamp,
                    image: itemRepository.attachmentDataForDisplay(item).flatMap { UIImage(data: $0) },
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
                    // Context menu actions (delete removed - use swipe instead)
                }
            }
        }
        .offset(x: offset)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    // Only respond to horizontal swipes
                    guard abs(dx) > abs(dy) else { return }
                    // Only allow left swipe (delete)
                    offset = min(0, dx)
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    // Only respond to horizontal swipes
                    guard abs(dx) > abs(dy) else {
                        offset = 0
                        return
                    }

                    withAnimation(Theme.Animations.motion(.spring(response: 0.3, dampingFraction: 0.7), reduceMotion: reduceMotion)) {
                        if dx < -100 {
                            // Swipe left > 100px triggers delete
                            offset = 0
                            onDelete()
                        } else {
                            // Snap back
                            offset = 0
                        }
                    }
                }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            handleTap()
        }
        .accessibilityAction(named: "Delete") {
            onDelete()
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
