// Purpose: Home feature — upcoming check-in timeline section.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI

/// Displays upcoming check-in items grouped by calendar date.
/// Only shows items with future follow-up dates — no overdue / past concept.
struct TimelineSection: View {
    let items: [Item]
    let onSnooze: (Item) -> Void
    let onClear: (Item) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    private var style: ThemeStyle { themeManager.currentStyle }

    private var dateGroups: [(label: String, items: [Item])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item -> Date in
            calendar.startOfDay(for: item.followUpDate ?? Date())
        }
        return grouped.keys
            .sorted()
            .map { date in
                (label: groupLabel(for: date, calendar: calendar), items: grouped[date] ?? [])
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Coming Up")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                .padding(.horizontal, Theme.Spacing.xs)

            if items.isEmpty {
                EmptyStateView(
                    iconName: Icons.calendar,
                    message: "Nothing coming up",
                    subtitle: "Set a check-in date on any item to see it here"
                )
            } else {
                ForEach(dateGroups, id: \.label) { group in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(group.label)
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                            .padding(.horizontal, Theme.Spacing.xs)

                        ForEach(group.items, id: \.id) { item in
                            TimelineItemRow(
                                item: item,
                                onSnooze: { onSnooze(item) },
                                onClear: { onClear(item) }
                            )
                        }
                    }
                }
            }
        }
    }

    /// Returns a human-friendly group label: "Today", "Tomorrow", weekday name, or date string.
    private func groupLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
