//
//  CapturesView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Primary view for raw thought captures awaiting organization.
//  Displays lifecycle state and input type with minimal UI friction.
//
//  Agent Navigation:
//  - CapturesView: Inbox list + capture sheet entry point
//  - TimelineView: ADHD-friendly visual timeline for today's captures
//  - CaptureRow: Single capture row styling
//

import SwiftData
import SwiftUI

struct CapturesView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showingCapture = false
    @State private var workflowService: CaptureWorkflowService?
    @State private var entries: [CaptureEntry] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if entries.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No captures yet",
                    message: "Capture a thought and it will land here."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(entries) { entry in
                    CaptureRow(entry: entry)
                }
                .onDelete(perform: deleteEntries)
            }
        }
        .navigationTitle("Captures")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCapture = true
                } label: {
                    Label("Capture", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingCapture, onDismiss: {
            _Concurrency.Task {
                await loadInbox()
            }
        }) {
            CaptureSheetView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            if workflowService == nil {
                workflowService = CaptureWorkflowService(modelContext: modelContext)
            }
            await loadInbox()
        }
        .refreshable {
            await loadInbox()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
            .accessibilityLabel("Dismiss error")
        } message: { message in
            Text(message)
        }
    }

    private func loadInbox() async {
        guard let workflowService else { return }
        do {
            entries = try workflowService.fetchInbox()
        } catch {
            // Error is already set in workflowService.errorMessage
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        guard let workflowService else { return }

        // Capture entries to delete BEFORE async operation
        let entriesToDelete = offsets.map { entries[$0] }

        _Concurrency.Task {
            do {
                // Serialize deletions
                for entry in entriesToDelete {
                    try await workflowService.deleteEntry(entry)
                }

                // Single reload after all deletions complete
                await loadInbox()
            } catch {
                // Show error to user
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct CaptureRow: View {
    let entry: CaptureEntry

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.rawText)
                .font(Theme.Typography.body)
                .lineLimit(2)

            HStack {
                Text(entry.createdAt, format: .dateTime)
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))

                if entry.entryInputType == .voice {
                    Image(systemName: "waveform")
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
                }

                if entry.currentLifecycleState != .raw {
                    Badge(text: entry.currentLifecycleState.rawValue, style: .accent)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let timeString = Self.timeFormatter.string(from: entry.createdAt)
        let inputType = entry.entryInputType == .voice ? "voice capture" : "text capture"
        return "\(timeString), \(inputType), \(entry.rawText)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct TimelineView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showNextUpIndicators") private var showNextUpIndicators = true

    @Query(sort: \CaptureEntry.createdAt, order: .reverse) private var entries: [CaptureEntry]

    @State private var selectedHour = Calendar.current.component(.hour, from: Date())

    private var todayEntries: [CaptureEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.createdAt) }
    }

    private var groupedEntries: [Int: [CaptureEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: todayEntries) { entry in
            calendar.component(.hour, from: entry.createdAt)
        }
    }

    private var selectedEntries: [CaptureEntry] {
        groupedEntries[selectedHour]?.sorted { $0.createdAt > $1.createdAt } ?? []
    }

    private var nextUpcomingHour: Int? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        return groupedEntries.keys
            .filter { $0 > currentHour }
            .sorted()
            .first
    }

    private var earliestHourWithCaptures: Int? {
        groupedEntries.keys.sorted().first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    hourStrip

                    if todayEntries.isEmpty {
                        EmptyStateView(
                            icon: "clock",
                            title: "No captures yet",
                            message: "Capture a thought and it will show up on today's timeline."
                        )
                    } else if selectedEntries.isEmpty {
                        Text("No captures for this hour.")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                            .padding(.horizontal, Theme.Spacing.md)
                        if let earliestHourWithCaptures, earliestHourWithCaptures != selectedHour {
                            Button("Jump to first capture") {
                                selectedHour = earliestHourWithCaptures
                            }
                            .buttonStyle(PressableButtonStyle())
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                    } else {
                        VStack(spacing: Theme.Spacing.md) {
                            ForEach(selectedEntries) { entry in
                                CardView {
                                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                        HStack {
                                            Text(entry.createdAt, format: .dateTime.hour().minute())
                                                .font(Theme.Typography.metadata)
                                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

                                            Spacer()

                                            if entry.entryInputType == .voice {
                                                Image(systemName: "waveform")
                                                    .font(Theme.Typography.metadata)
                                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                                            } else {
                                                Image(systemName: "text.alignleft")
                                                    .font(Theme.Typography.metadata)
                                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                                            }
                                        }

                                        Text(entry.rawText)
                                            .font(Theme.Typography.body)
                                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme))
                                            .lineLimit(3)

                                        if entry.currentLifecycleState != .raw {
                                            Badge(text: entry.currentLifecycleState.rawValue, style: .accent)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(timelineEntryLabel(entry))
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                }
                .padding(.vertical, Theme.Spacing.lg)
            }
            .background(Theme.Colors.background(colorScheme))
            .navigationTitle("Timeline")
        }
        .onAppear {
            let calendar = Calendar.current
            if let firstHour = earliestHourWithCaptures {
                selectedHour = firstHour
            } else {
                selectedHour = calendar.component(.hour, from: Date())
            }
        }
    }

    private var hourStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0 ..< 24, id: \.self) { hour in
                    let count = groupedEntries[hour]?.count ?? 0
                    Button {
                        selectedHour = hour
                    } label: {
                        VStack(spacing: Theme.Spacing.xs) {
                            Text(hourLabel(hour))
                                .font(Theme.Typography.badgeEmphasis)
                                .foregroundStyle(hour == selectedHour
                                    ? Theme.Colors.textPrimary(colorScheme)
                                    : Theme.Colors.textSecondary(colorScheme))

                            if count > 0 {
                                Badge(text: "\(count)", style: .neutral)
                            } else {
                                Text("0")
                                    .font(Theme.Typography.badge)
                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                            }

                            if showNextUpIndicators, let nextHour = nextUpcomingHour, nextHour == hour {
                                Badge(text: "Next up", style: .accent)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(hourBackground(hour))
                        .cornerRadius(Theme.CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                .stroke(
                                    Theme.Colors.borderMuted(colorScheme),
                                    lineWidth: hour == selectedHour ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(hourLabel(hour)) hour")
                    .accessibilityValue(accessibilityValue(for: hour, count: count))
                    .accessibilityHint("Double-tap to show captures from this hour")
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private func hourBackground(_ hour: Int) -> some View {
        Group {
            if hour == selectedHour {
                Theme.Gradients.accentPrimary(colorScheme).opacity(0.2)
            } else {
                Theme.Colors.surface(colorScheme)
            }
        }
    }

    private func accessibilityValue(for hour: Int, count: Int) -> String {
        var value = count == 1 ? "1 capture" : "\(count) captures"
        if showNextUpIndicators, let nextHour = nextUpcomingHour, nextHour == hour {
            value += ", next up"
        }
        return value
    }

    private func timelineEntryLabel(_ entry: CaptureEntry) -> String {
        let timeString = entry.createdAt.formatted(date: .omitted, time: .shortened)
        let inputType = entry.entryInputType == .voice ? "voice capture" : "text capture"
        return "\(timeString), \(inputType), \(entry.rawText)"
    }
}

#Preview {
    NavigationStack {
        CapturesView()
    }
    .modelContainer(PersistenceController.preview)
    .environmentObject(ThemeManager.shared)
}

#Preview("Timeline") {
    TimelineView()
        .modelContainer(PersistenceController.preview)
}
