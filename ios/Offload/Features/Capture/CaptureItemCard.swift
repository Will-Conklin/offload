// Purpose: Item card view for CaptureView.
// Authority: Code-level
// Governed by: CLAUDE.md

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
    let onBreakdown: () -> Void
    let onBrainDump: () -> Void
    let onDecisionFatigue: () -> Void
    let onExecFunction: () -> Void
    var onDraftCommunication: (() -> Void)?

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
                VStack(alignment: .leading, spacing: 0) {
                    MCMCardContent(
                        icon: communicationIcon ?? item.itemType?.icon,
                        title: item.content,
                        typeLabel: communicationTypeLabel ?? item.itemType?.displayName,
                        timestamp: item.relativeTimestamp,
                        image: itemRepository.attachmentDataForDisplay(item).flatMap { UIImage(data: $0) },
                        tags: item.tags,
                        onAddTag: onAddTag,
                        size: .compact
                    )

                    if let commMeta = item.communicationMetadata {
                        communicationBar(commMeta)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                StarButton(isStarred: item.isStarred, action: onToggleStar)
            }
            .overlay(alignment: .topTrailing) {
                if item.isBrainDumpCandidate {
                    Button(action: onBrainDump) {
                        Label("Brain Dump?", systemImage: Icons.brainDump)
                            .font(Theme.Typography.badge)
                            .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(Theme.Spacing.sm)
                    .accessibilityLabel("Compile Brain Dump")
                    .accessibilityHint("Extracts and categorizes items from this capture")
                } else if item.isStuckCandidate {
                    Button(action: onExecFunction) {
                        Label("Stuck?", systemImage: Icons.execFunction)
                            .font(Theme.Typography.badge)
                            .foregroundStyle(Theme.Colors.accentSecondary(colorScheme, style: style))
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(Theme.Colors.accentSecondary(colorScheme, style: style).opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(Theme.Spacing.sm)
                    .accessibilityLabel("Get unstuck")
                    .accessibilityHint("Suggests strategies to help you get started")
                }
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
        .accessibilityAction(named: AdvancedAccessibilityActionPolicy.breakdownActionName) {
            onBreakdown()
        }
        .accessibilityAction(named: AdvancedAccessibilityActionPolicy.brainDumpActionName) {
            onBrainDump()
        }
        .accessibilityAction(named: AdvancedAccessibilityActionPolicy.decisionFatigueActionName) {
            onDecisionFatigue()
        }
        .accessibilityAction(named: "I'm Stuck") {
            onExecFunction()
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

            Button {
                onBreakdown()
            } label: {
                Label {
                    Text("Break Down")
                } icon: {
                    AppIcon(name: Icons.breakdown, size: 14)
                }
            }

            Button {
                onBrainDump()
            } label: {
                Label {
                    Text("Compile Brain Dump")
                } icon: {
                    AppIcon(name: Icons.brainDump, size: 14)
                }
            }

            Button {
                onDecisionFatigue()
            } label: {
                Label {
                    Text("Get Options")
                } icon: {
                    AppIcon(name: Icons.decisionFatigue, size: 14)
                }
            }

            Button {
                onExecFunction()
            } label: {
                Label {
                    Text("I'm Stuck")
                } icon: {
                    AppIcon(name: Icons.execFunction, size: 14)
                }
            }

            if item.itemType == .communication, let onDraft = onDraftCommunication {
                Button {
                    onDraft()
                } label: {
                    Label {
                        Text("Draft with AI")
                    } icon: {
                        AppIcon(name: Icons.write, size: 14)
                    }
                }
            }
        }
    }

    /// Shows the channel-specific icon for communication items instead of the generic type icon.
    private var communicationIcon: String? {
        item.communicationMetadata?.channel.icon
    }

    /// Shows a more specific type label like "Call" or "Email" for communication items.
    private var communicationTypeLabel: String? {
        item.communicationMetadata?.channel.displayName
    }

    /// Renders a contact name and one-touch action button below the card content.
    private func communicationBar(_ meta: CommunicationMetadata) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let name = meta.contactName {
                Image(systemName: Icons.contactLink)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                Text(name)
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                    .lineLimit(1)
            }

            Spacer()

            if let contactValue = meta.contactValue {
                Button {
                    CommunicationActionService.performAction(
                        channel: meta.channel,
                        contactValue: contactValue,
                        subject: item.content
                    )
                } label: {
                    Label(meta.channel.displayName, systemImage: meta.channel.icon)
                        .font(Theme.Typography.badge)
                        .foregroundStyle(Theme.Colors.secondaryButtonText(colorScheme, style: style))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.secondary(colorScheme, style: style))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(meta.channel.displayName) \(meta.contactName ?? "")")
                .accessibilityHint("Opens \(meta.channel.displayName.lowercased()) app.")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }
}
