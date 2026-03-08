// Purpose: Home feature — a single row in the Coming Up timeline.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

/// A compact card row representing an item with an upcoming follow-up date.
/// Provides snooze (+1 day) and clear (remove date) actions — no urgency styling.
struct TimelineItemRow: View {
    let item: Item
    let onSnooze: () -> Void
    let onClear: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        CardSurface(showsBorder: true, contentPadding: EdgeInsets(top: Theme.Spacing.sm, leading: Theme.Spacing.sm, bottom: Theme.Spacing.sm, trailing: Theme.Spacing.xs)) {
            HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                // Item info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(item.content.isEmpty ? "Untitled" : item.content)
                        .font(Theme.Typography.cardBody)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        .lineLimit(2)

                    if let followUpDate = item.followUpDate {
                        Text(relativeDateLabel(for: followUpDate))
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Actions
                HStack(spacing: Theme.Spacing.xs) {
                    ItemActionButton(
                        iconName: Icons.clock,
                        tint: Theme.Colors.textSecondary(colorScheme, style: style),
                        label: "Snooze one day",
                        action: onSnooze
                    )
                    ItemActionButton(
                        iconName: Icons.xmark,
                        tint: Theme.Colors.textSecondary(colorScheme, style: style),
                        label: "Clear check-in date",
                        action: onClear
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.content), follow up \(item.followUpDate.map { relativeDateLabel(for: $0) } ?? "")")
    }

    /// Returns a human-friendly relative label for a date: "Today", "Tomorrow", or "in N days".
    private func relativeDateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        return days > 0 ? "in \(days) days" : "Today"
    }
}
