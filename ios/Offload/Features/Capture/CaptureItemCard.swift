// Purpose: Item card view for CaptureView.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI
import UIKit

// MARK: - Item Card

struct ItemCard: View {
    let item: Item
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onToggleStar: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void
    let onMoveTo: (MoveDestination) -> Void

    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swipeOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isSwipeDragging = false

    private let swipeModel = SwipeInteractionModel.capture

    var body: some View {
        ZStack(alignment: .trailing) {
            SwipeAffordance(
                side: .trailing,
                iconName: Icons.deleteFilled,
                color: Theme.Colors.destructive(colorScheme, style: style),
                progress: swipeModel.trailingProgress(offset: swipeOffset),
                isEnabled: swipeOffset <= swipeModel.revealedOffset,
                accessibilityLabel: "Delete item",
                accessibilityHint: "Deletes this capture item."
            ) {
                withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                    swipeOffset = 0
                }
                onDelete()
            }

            CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
                MCMCardContent(
                    icon: item.itemType?.icon,
                    title: item.content,
                    typeLabel: item.type?.uppercased(),
                    timestamp: item.relativeTimestamp,
                    image: itemRepository.attachmentDataForDisplay(item).flatMap { UIImage(data: $0) },
                    tags: item.tags,
                    onAddTag: onAddTag,
                    size: .compact // Compact size for item cards
                )
            }
            .overlay(alignment: .bottomTrailing) {
                StarButton(isStarred: item.isStarred, action: onToggleStar)
            }
            .overlay {
                HStack {
                    if swipeOffset > 0 {
                        AppIcon(name: Icons.checkCircleFilled, size: 18)
                            .foregroundStyle(Theme.Colors.terminalGreen(colorScheme, style: style))
                            .padding(.leading, Theme.Spacing.md)
                            .opacity(min(1, Double(swipeOffset / swipeModel.maxLeadingOffset)))
                    }
                    Spacer()
                }
            }
            .offset(x: swipeOffset)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !swipeModel.isRevealed(offset: swipeOffset) else {
                    withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                        swipeOffset = 0
                    }
                    return
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap()
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if !isSwipeDragging {
                            dragStartOffset = swipeOffset
                            isSwipeDragging = true
                        }
                        guard let dragOffset = swipeModel.dragOffset(
                            startOffset: dragStartOffset,
                            translation: value.translation
                        ) else {
                            return
                        }
                        swipeOffset = dragOffset
                    }
                    .onEnded { value in
                        let endState = swipeModel.endState(
                            startOffset: dragStartOffset,
                            translation: value.translation
                        )
                        isSwipeDragging = false

                        withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                            switch endState {
                            case .triggerLeadingAction:
                                swipeOffset = 0
                                onComplete()
                            case .triggerTrailingAction:
                                swipeOffset = 0
                                onDelete()
                            case .revealed:
                                swipeOffset = swipeModel.revealedOffset
                            case .closed:
                                swipeOffset = 0
                            }
                        }
                    }
            )
        }
        .accessibilityAction(named: "Complete") {
            onComplete()
        }
        .accessibilityAction(named: "Delete") {
            onDelete()
        }
        .accessibilityAction(named: AdvancedAccessibilityActionPolicy.starToggleActionName(isStarred: item.isStarred)) {
            onToggleStar()
        }
        .accessibilityAction(named: AdvancedAccessibilityActionPolicy.moveDestinationActionName(.plan)) {
            onMoveTo(.plan)
        }
        .accessibilityAction(named: AdvancedAccessibilityActionPolicy.moveDestinationActionName(.list)) {
            onMoveTo(.list)
        }
        .accessibilityElement(children: .combine)
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
