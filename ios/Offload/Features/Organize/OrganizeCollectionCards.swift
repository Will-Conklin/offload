// Purpose: Collection card views for OrganizeView.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI

// MARK: - Draggable Collection Card

struct DraggableCollectionCard: View {
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onToggleStar: () -> Void
    let onDrop: (UUID, UUID) -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onConvert: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        CollectionCard(
            collection: collection,
            colorScheme: colorScheme,
            style: style,
            onAddTag: onAddTag,
            onToggleStar: onToggleStar
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .draggable(collection.id.uuidString) {
            // Preview while dragging
            Text(collection.name)
                .font(Theme.Typography.caption)
                .lineLimit(2)
                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                .padding(Theme.Spacing.sm)
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(Theme.Colors.cardColor(index: collection.stableColorIndex, colorScheme, style: style))
                )
        }
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let droppedIdString = droppedIds.first,
                  let droppedId = UUID(uuidString: droppedIdString)
            else {
                return false
            }

            // Prevent dropping on self
            if droppedId == collection.id {
                return false
            }

            onDrop(droppedId, collection.id)
            return true
        } isTargeted: { isTargeted in
            withAnimation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion)) {
                isDropTarget = isTargeted
            }
        }
        .overlay(alignment: .top) {
            // Show insertion line when dropping
            if isDropTarget {
                Rectangle()
                    .fill(Theme.Colors.primary(colorScheme, style: style))
                    .frame(height: 3)
                    .offset(y: -(Theme.Spacing.md / 2 + 1.5))
                    .transition(.opacity)
            }
        }
        .animation(Theme.Animations.motion(.easeInOut(duration: 0.2), reduceMotion: reduceMotion), value: isDropTarget)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Move up") {
            onMoveUp?()
        }
        .accessibilityAction(named: "Move down") {
            onMoveDown?()
        }
        .overlay(alignment: .topTrailing) {
            if let onConvert {
                Button(action: onConvert) {
                    IconTile(
                        iconName: Icons.more,
                        iconSize: 12,
                        tileSize: 28,
                        style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .padding(Theme.Spacing.sm)
                .accessibilityLabel("Collection actions")
                .accessibilityHint("Show options for this collection")
            }
        }
    }
}

// MARK: - Bottom Collection Drop Zone

struct BottomCollectionDropZone: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onDrop: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
            .fill(isDropTarget
                ? Theme.Colors.primary(colorScheme, style: style).opacity(0.08)
                : Color.white.opacity(0.001)
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

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onAddTag: () -> Void
    let onToggleStar: () -> Void

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: collection.stableColorIndex, colorScheme, style: style)) {
            // MCM card content with custom metadata for collections
            HStack(alignment: .top, spacing: 0) {
                // Left column (narrow - metadata gutter)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    IconTile(
                        iconName: collection.isStructured ? Icons.plans : Icons.lists,
                        iconSize: 16,
                        tileSize: 36,
                        style: .none(Theme.Colors.icon(colorScheme, style: style))
                    )

                    Text(collection.isStructured ? "PLAN" : "LIST")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                    Text(collection.formattedDate)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                    if let count = collection.collectionItems?.count, count > 0 {
                        Text("\(count) item\(count == 1 ? "" : "s")")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                }
                .frame(width: 60, alignment: .leading)

                // Right column (wide - main content)
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(collection.name)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        .lineLimit(3)

                    // Tags in flow layout - always show if onAddTag is available
                    FlowLayout(spacing: Theme.Spacing.xs) {
                        ForEach(collection.tags, id: \.id) { tag in
                            TagPill(
                                name: tag.name,
                                color: tag.color
                                    .map { Color(hex: $0) }
                                    ?? Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                            )
                        }

                        Button(action: onAddTag) {
                            HStack(spacing: Theme.Spacing.xs) {
                                AppIcon(name: Icons.add, size: 8)
                                Text("TAG")
                                    .font(Theme.Typography.badge)
                                    .tracking(0.5)
                            }
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                Capsule()
                                    .strokeBorder(
                                        Theme.Colors.primary(colorScheme, style: style),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 12)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            StarButton(isStarred: collection.isStarred, action: onToggleStar)
        }
    }
}
