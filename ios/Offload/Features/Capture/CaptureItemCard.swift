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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var crtFlickerOpacity: Double = 1

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
            MCMCardContent(
                icon: item.itemType?.icon,
                title: item.content,
                typeLabel: item.type?.uppercased(),
                timestamp: item.relativeTimestamp,
                image: item.attachmentData.flatMap { UIImage(data: $0) },
                tags: item.tags,
                onAddTag: onAddTag,
                size: .compact // Compact size for item cards
            )
        }
        .overlay(alignment: .bottomTrailing) {
            StarButton(isStarred: item.isStarred, action: onToggleStar)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .overlay(
            // Swipe indicators
            HStack {
                if offset > 0 {
                    AppIcon(name: Icons.checkCircleFilled, size: 18)
                        .foregroundStyle(Theme.Colors.terminalGreen(colorScheme, style: style))
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
        .simultaneousGesture(
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

                    withAnimation(reduceMotion ? .default : .spring(response: 0.3, dampingFraction: 0.7)) {
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
        .accessibilityAction(named: "Complete") {
            onComplete()
        }
        .accessibilityAction(named: "Delete") {
            onDelete()
        }
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
