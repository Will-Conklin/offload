// Purpose: Home Screen widgets — small "Offload" button + medium recent-captures view.
// Authority: Code-level
// Governed by: CLAUDE.md

import AppIntents
import SwiftUI
import WidgetKit

// Burnt orange — matches Theme.Colors.accentPrimary light-mode value (#D35400).
// Defined once here because the widget target cannot import the main app's Theme module.
private let widgetAccentColor = Color(red: 0.827, green: 0.329, blue: 0.0)

// MARK: - Timeline Entry

struct OffloadWidgetEntry: TimelineEntry {
    let date: Date
    let recentCaptures: [String]
}

// MARK: - Timeline Provider

struct OffloadWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> OffloadWidgetEntry {
        OffloadWidgetEntry(date: Date(), recentCaptures: ["Remember to call the dentist", "Review project proposal"])
    }

    func getSnapshot(in context: Context, completion: @escaping (OffloadWidgetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OffloadWidgetEntry>) -> Void) {
        // Refresh every 15 minutes so recently added captures surface quickly.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry()], policy: .after(nextRefresh)))
    }

    private func entry() -> OffloadWidgetEntry {
        // Read pending captures from App Group as a cheap proxy for "recent" items.
        // The main app writes new captures here; widget shows them until the next refresh.
        let recent = PendingCaptureStore.load()
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map(\.content)
        return OffloadWidgetEntry(date: Date(), recentCaptures: Array(recent))
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    var body: some View {
        Link(destination: URL(string: "offload://capture")!) {
            ZStack {
                widgetAccentColor
                VStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                    Text("Offload")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                }
            }
        }
        .accessibilityLabel("Open Offload capture")
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: OffloadWidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left column: Offload button
            Link(destination: URL(string: "offload://capture")!) {
                ZStack {
                    Color(red: 0.82, green: 0.38, blue: 0.19)
                    VStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Offload")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Open Offload capture")

            // Right column: recent captures
            VStack(alignment: .leading, spacing: 4) {
                if entry.recentCaptures.isEmpty {
                    Text("No recent captures")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(Array(entry.recentCaptures.prefix(3).enumerated()), id: \.offset) { _, text in
                        Text(text)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        if text != entry.recentCaptures.prefix(3).last {
                            Divider()
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Widget Declarations

struct OffloadSmallWidget: Widget {
    static let kind = "OffloadSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: OffloadWidgetProvider()) { _ in
            SmallWidgetView()
        }
        .configurationDisplayName("Offload")
        .description("One-tap capture from the home screen.")
        .supportedFamilies([.systemSmall])
    }
}

struct OffloadMediumWidget: Widget {
    static let kind = "OffloadMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: OffloadWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Offload")
        .description("Capture button + recent captures at a glance.")
        .supportedFamilies([.systemMedium])
    }
}
