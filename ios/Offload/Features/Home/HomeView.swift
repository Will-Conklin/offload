// Purpose: Home feature dashboard — activity stats, support nudge, active collections, and coming-up timeline.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

import SwiftData
import SwiftUI

struct HomeView: View {
    var navigateToOrganize: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var style: ThemeStyle { themeManager.currentStyle }

    @State private var viewModel = HomeViewModel()
    @State private var showCelebration = false
    @AppStorage("home.supportNudgeDismissed") private var nudgeDismissed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    activityCard
                    if let message = viewModel.supportNudgeMessage, !nudgeDismissed {
                        SupportNudgeCard(message: message, onDismiss: { nudgeDismissed = true })
                    }
                    activeCollectionsRow
                    TimelineSection(
                        items: viewModel.timelineItems,
                        onSnooze: snoozeItem,
                        onClear: clearFollowUp
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.lg)
            }
            .background(Theme.Gradients.deepBackground(colorScheme).ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadStats() }
        }
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        CardSurface {
            HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                statColumn(value: viewModel.capturedThisWeek, label: "captured\nthis week")
                Divider()
                statColumn(value: viewModel.completedThisWeek, label: "done\nthis week")
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .celebrationOverlay(style: .itemCompleted, isActive: $showCelebration)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Captured this week: \(viewModel.capturedThisWeek). Done this week: \(viewModel.completedThisWeek).")
    }

    private func statColumn(value: Int, label: String) -> some View {
        VStack(alignment: .center, spacing: Theme.Spacing.xs) {
            Text("\(value)")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
            Text(label)
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Active Collections Row

    private var activeCollectionsRow: some View {
        Group {
            if viewModel.activeCollectionCount > 0 {
                Button(action: navigateToOrganize) {
                    CardSurface(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
                        HStack {
                            Text("\(viewModel.activeCollectionCount) active collection\(viewModel.activeCollectionCount == 1 ? "" : "s")")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            Spacer()
                            AppIcon(name: Icons.chevronRight, size: 14)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(viewModel.activeCollectionCount) active collection\(viewModel.activeCollectionCount == 1 ? "" : "s")")
                .accessibilityHint("Opens Organize tab")
            } else {
                CardSurface(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
                    Text("No active collections")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
                .accessibilityLabel("No active collections")
            }
        }
    }

    // MARK: - Data Loading

    private func loadStats() async {
        try? await viewModel.loadStats(using: itemRepository, collectionRepository: collectionRepository)
        if viewModel.completedThisWeek > 0 && !showCelebration {
            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                showCelebration = true
            }
        }
    }

    // MARK: - Timeline Actions

    private func snoozeItem(_ item: Item) {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: item.followUpDate ?? Date()) ?? Date()
        try? itemRepository.updateFollowUpDate(item, date: nextDay)
        try? viewModel.reloadTimeline(using: itemRepository)
    }

    private func clearFollowUp(_ item: Item) {
        try? itemRepository.updateFollowUpDate(item, date: nil)
        try? viewModel.reloadTimeline(using: itemRepository)
    }
}

#Preview {
    HomeView(navigateToOrganize: {})
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
