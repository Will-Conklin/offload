//
//  SettingsView.swift
//  Offload
//
//  Created by Claude Code on 1/5/26.
//
//  Intent: Comprehensive settings interface for app configuration, preferences,
//  and information. Provides foundation for future AI/backend configuration.
//
//  Agent Navigation:
//  - Preferences: Capture defaults + voice settings
//  - ADHD Support: Timeline/animation toggles
//  - Organization: Categories + tags
//  - Data Management: Storage + cleanup
//

import OSLog
import SwiftData
import SwiftUI

// MARK: - Constants

private enum Constants {
    static let githubURL = URL(string: "https://github.com/Will-Conklin/offload")!
    static let issuesURL = URL(string: "https://github.com/Will-Conklin/offload/issues")!
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Tag.name) private var tags: [Tag]

    @AppStorage("defaultCaptureSource") private var defaultCaptureSource = CaptureSource.app
    @AppStorage("autoArchiveCompleted") private var autoArchiveCompleted = false
    @AppStorage("enableAISuggestions") private var enableAISuggestions = false
    @AppStorage("apiEndpoint") private var apiEndpoint = "https://api.offload.app"
    @AppStorage("showTimelineTab") private var showTimelineTab = true
    @AppStorage("showNextUpIndicators") private var showNextUpIndicators = true
    @AppStorage("enableCelebrationAnimations") private var enableCelebrationAnimations = true

    @State private var showingClearCompletedAlert = false
    @State private var showingArchiveOldAlert = false
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var activeSheet: SettingsSheet?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // App Info Section
                appInfoSection

                // Preferences Section
                preferencesSection

                // ADHD Support Section
                adhdSupportSection

                // Organization Section
                organizationSection

                // AI & Hand-Off Section
                aiHandOffSection

                // Data Management Section
                dataManagementSection

                // About & Legal Section
                aboutLegalSection
            }
            .navigationTitle("Settings")
        }
        .alert("Clear Completed Tasks?", isPresented: $showingClearCompletedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearCompletedTasks()
            }
        } message: {
            Text("This will permanently delete all completed tasks. This cannot be undone.")
        }
        .alert("Archive Old Captures?", isPresented: $showingArchiveOldAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Archive", role: .destructive) {
                archiveOldCaptures()
            }
        } message: {
            Text("This will archive all captures older than 30 days.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicySheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .category:
                CategoryFormSheet { name, icon in
                    try createCategory(name: name, icon: icon)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            case .tag:
                TagFormSheet { name, color in
                    try createTag(name: name, color: color)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
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

    // MARK: - ADHD Support Section

    private var adhdSupportSection: some View {
        Section {
            Toggle("Show Timeline Tab", isOn: $showTimelineTab)
                .accessibilityHint("Shows the Timeline tab in the tab bar")

            Toggle("Show Next Up Indicators", isOn: $showNextUpIndicators)
                .accessibilityHint("Highlights the next hour with upcoming captures")

            Toggle("Celebration Animations", isOn: $enableCelebrationAnimations)
                .accessibilityHint("Shows a sparkle effect when tasks are completed")
        } header: {
            Text("ADHD Support")
        } footer: {
            Text("Customize gentle cues and visual supports. Turn off animations if they feel distracting.")
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))

                Text("Offload")
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)

                Text("Capture First, Organize Later")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

                HStack(spacing: 4) {
                    Text("Version")
                    Text(appVersion)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    Text("(\(buildNumber))")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                        .font(Theme.Typography.caption)
                }
                .font(Theme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        Section {
            Picker("Color Theme", selection: $themeManager.currentStyle) {
                ForEach(ThemeStyle.allCases) { style in
                    VStack(alignment: .leading) {
                        Text(style.rawValue)
                        Text(style.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(style)
                }
            }

            Picker("Default Capture Source", selection: $defaultCaptureSource) {
                Text("App").tag(CaptureSource.app)
                Text("Shortcut").tag(CaptureSource.shortcut)
                Text("Share Sheet").tag(CaptureSource.shareSheet)
                Text("Widget").tag(CaptureSource.widget)
            }

            Toggle("Auto-Archive Completed Items", isOn: $autoArchiveCompleted)

            NavigationLink {
                VoiceSettingsView()
            } label: {
                Label("Voice Recording", systemImage: "waveform")
            }
            .accessibilityHint("Opens voice recording settings")
        } header: {
            Text("Preferences")
        } footer: {
            Text("Color themes help personalize your experience. Changes apply immediately to both light and dark modes. Auto-archive will move completed tasks and placed captures to archive after 7 days.")
        }
    }

    // MARK: - Organization Section

    private var organizationSection: some View {
        Section {
            // Categories subsection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Categories")
                        .font(Theme.Typography.headline)
                    Spacer()
                    Button {
                        activeSheet = .category
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                    }
                    .accessibilityLabel("Add category")
                    .accessibilityHint("Opens a form to create a new category")
                }

                if categories.isEmpty {
                    Text("No categories yet")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                } else {
                    ForEach(categories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            if let icon = category.icon, !icon.isEmpty {
                                Text(icon)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)

            Divider()

            // Tags subsection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tags")
                        .font(Theme.Typography.headline)
                    Spacer()
                    Button {
                        activeSheet = .tag
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                    }
                    .accessibilityLabel("Add tag")
                    .accessibilityHint("Opens a form to create a new tag")
                }

                if tags.isEmpty {
                    Text("No tags yet")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                } else {
                    ForEach(tags) { tag in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tag.name)
                            if let color = tag.color, !color.isEmpty {
                                Text(color)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        } header: {
            Text("Organization")
        } footer: {
            Text("Categories and tags help organize your captures and plans.")
        }
    }

    // MARK: - AI & Hand-Off Section

    private var aiHandOffSection: some View {
        Section {
            Toggle("Enable AI Suggestions", isOn: $enableAISuggestions)
                .disabled(true) // Disabled until backend is implemented
                .accessibilityHint("AI suggestions are not yet available")

            if enableAISuggestions {
                NavigationLink {
                    APIConfigurationView(apiEndpoint: $apiEndpoint)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Configuration")
                        Text(apiEndpoint)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                            .lineLimit(1)
                    }
                }
                .disabled(true)
                .accessibilityHint("API configuration is coming soon")
            }

            NavigationLink {
                AIInfoView()
            } label: {
                Label("How AI Suggestions Work", systemImage: "info.circle")
            }
            .accessibilityHint("Explains how AI suggestions will work")
        } header: {
            Text("AI & Organization")
        } footer: {
            Text("AI suggestions are currently under development. When enabled, Offload will help organize your captures into plans, tasks, and lists.")
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section {
            Button {
                showingClearCompletedAlert = true
            } label: {
                Label("Clear Completed Tasks", systemImage: "checkmark.circle")
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Permanently deletes all completed tasks")

            Button {
                showingArchiveOldAlert = true
            } label: {
                Label("Archive Old Captures", systemImage: "archivebox")
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Archives captures older than 30 days")

            NavigationLink {
                StorageInfoView()
            } label: {
                Label("Storage Usage", systemImage: "internaldrive")
            }
            .accessibilityHint("Shows local storage usage for captures and lists")
        } header: {
            Text("Data Management")
        } footer: {
            Text("All data is stored locally on your device. No cloud sync is currently enabled.")
        }
    }

    // MARK: - About & Legal Section

    private var aboutLegalSection: some View {
        Section("About & Legal") {
            Button {
                showingAbout = true
            } label: {
                Label("About Offload", systemImage: "info.circle")
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Shows app version and acknowledgements")

            Button {
                showingPrivacyPolicy = true
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Shows Offload privacy policy")

            Link(destination: Constants.githubURL) {
                Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .accessibilityHint("Opens the Offload repository in your browser")

            Button {
                openURL(Constants.issuesURL)
            } label: {
                Label("Report an Issue", systemImage: "exclamationmark.bubble")
                    .foregroundStyle(.primary)
            }
            .accessibilityHint("Opens the issue tracker in your browser")
        }
    }

    // MARK: - Helper Methods

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func clearCompletedTasks() {
        let taskRepo = TaskRepository(modelContext: modelContext)

        do {
            let allTasks = try taskRepo.fetchAll()
            let completedTasks = allTasks.filter(\.isDone)

            for task in completedTasks {
                try taskRepo.delete(task: task)
            }
        } catch {
            AppLogger.persistence.error("Clear completed tasks failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func archiveOldCaptures() {
        let captureRepo = CaptureRepository(modelContext: modelContext)

        do {
            let allCaptures = try captureRepo.fetchAll()
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let oldCaptures = allCaptures.filter { $0.createdAt < thirtyDaysAgo }

            for capture in oldCaptures {
                try captureRepo.updateLifecycleState(entry: capture, to: .archived)
            }
        } catch {
            AppLogger.persistence.error("Archive old captures failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func createCategory(name: String, icon: String?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("Category name is required.")
        }

        let normalizedIcon = icon?.trimmingCharacters(in: .whitespacesAndNewlines)
        let repository = CategoryRepository(modelContext: modelContext)
        _ = try repository.findOrCreate(
            name: trimmedName,
            icon: (normalizedIcon?.isEmpty ?? true) ? nil : normalizedIcon
        )
    }

    private func createTag(name: String, color: String?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("Tag name is required.")
        }

        let normalizedColor = color?.trimmingCharacters(in: .whitespacesAndNewlines)
        let repository = TagRepository(modelContext: modelContext)
        _ = try repository.findOrCreate(
            name: trimmedName,
            color: (normalizedColor?.isEmpty ?? true) ? nil : normalizedColor
        )
    }
}

// MARK: - Supporting Enums

private enum SettingsSheet: Identifiable {
    case category
    case tag

    var id: String {
        switch self {
        case .category:
            "category"
        case .tag:
            "tag"
        }
    }
}

// MARK: - Supporting Views

private struct VoiceSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("voiceRecordingQuality") private var recordingQuality = "high"
    @AppStorage("enableLiveTranscription") private var enableLiveTranscription = true

    var body: some View {
        Form {
            Section {
                Picker("Recording Quality", selection: $recordingQuality) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }

                Toggle("Enable Live Transcription", isOn: $enableLiveTranscription)
                    .accessibilityHint("Uses on-device speech recognition while recording")
            } header: {
                Text("Recording")
            } footer: {
                Text("Higher quality recordings use more storage. Live transcription uses the on-device Speech framework.")
            }

            Section("Privacy") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Voice recordings are processed entirely on your device using Apple's Speech Recognition framework.")
                        .font(Theme.Typography.caption)

                    Text("No audio data is sent to external servers.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.success(colorScheme, style: themeManager.currentStyle))
                        .fontWeight(.medium)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .navigationTitle("Voice Recording")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct APIConfigurationView: View {
    @Binding var apiEndpoint: String
    @State private var tempEndpoint: String
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(apiEndpoint: Binding<String>) {
        _apiEndpoint = apiEndpoint
        _tempEndpoint = State(initialValue: apiEndpoint.wrappedValue)
    }

    var body: some View {
        Form {
            Section {
                TextField("URL", text: $tempEndpoint)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .accessibilityLabel("API endpoint URL")
            } header: {
                Text("API Endpoint")
            } footer: {
                Text("Must be a valid HTTPS URL")
                    .font(Theme.Typography.caption)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(Theme.Typography.caption)
                }
            }

            Section {
                Button("Reset to Default") {
                    tempEndpoint = "https://api.offload.app"
                    errorMessage = nil
                }
                .accessibilityHint("Restores the default API endpoint")
            }
        }
        .navigationTitle("API Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    handleSave()
                }
                .accessibilityHint("Saves the API endpoint")
            }
        }
    }

    private func handleSave() {
        errorMessage = nil

        // Validate URL
        let trimmed = tempEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "URL cannot be empty"
            return
        }

        guard let url = URL(string: trimmed) else {
            errorMessage = "Invalid URL format"
            return
        }

        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            errorMessage = "URL must use HTTPS for security"
            return
        }

        guard let host = url.host, !host.isEmpty else {
            errorMessage = "URL must have a valid hostname"
            return
        }

        guard trimmed.count <= 200 else {
            errorMessage = "URL is too long (max 200 characters)"
            return
        }

        // Valid - save and dismiss
        apiEndpoint = trimmed
        dismiss()
    }
}

private struct AIInfoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How AI Suggestions Work")
                        .font(Theme.Typography.title2)
                        .fontWeight(.bold)

                    Text("Offload uses AI to help organize your captures into actionable items.")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }

                Divider()

                FeatureCard(
                    icon: "brain",
                    title: "Intelligent Organization",
                    description: "AI analyzes your captures and suggests organizing them into plans, tasks, lists, or communication items."
                )

                FeatureCard(
                    icon: "hand.raised.fill",
                    title: "You Stay in Control",
                    description: "AI only suggests—it never automatically modifies your data. You review and approve every suggestion."
                )

                FeatureCard(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "When enabled, suggestions are generated using secure API calls. Your data is never stored on external servers permanently."
                )

                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Learns Your Patterns",
                    description: "Over time, the AI learns your organization preferences to provide more relevant suggestions."
                )

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Coming Soon")
                        .font(Theme.Typography.headline)

                    Text("AI suggestions are currently under development. When available, you'll be able to enable this feature in Settings.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }
                .padding()
                .background(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle).opacity(0.1))
                .cornerRadius(Theme.CornerRadius.md)
            }
            .padding()
        }
        .navigationTitle("AI Suggestions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.headline)

                Text(description)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
            }
        }
        .padding()
        .background(Theme.Colors.surface(colorScheme))
        .cornerRadius(Theme.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.borderMuted(colorScheme), lineWidth: 1)
        )
    }
}

private struct StorageInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var captureCount = 0
    @State private var planCount = 0
    @State private var taskCount = 0
    @State private var listCount = 0
    @State private var commCount = 0

    var body: some View {
        List {
            Section("Data Overview") {
                HStack {
                    Label("Captures", systemImage: "tray")
                    Spacer()
                    Text("\(captureCount)")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }

                HStack {
                    Label("Plans", systemImage: "folder")
                    Spacer()
                    Text("\(planCount)")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }

                HStack {
                    Label("Tasks", systemImage: "checklist")
                    Spacer()
                    Text("\(taskCount)")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }

                HStack {
                    Label("Lists", systemImage: "list.bullet")
                    Spacer()
                    Text("\(listCount)")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }

                HStack {
                    Label("Communications", systemImage: "message")
                    Spacer()
                    Text("\(commCount)")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }
            }

            Section {
                HStack {
                    Label("Device Storage", systemImage: "internaldrive")
                    Spacer()
                    Text("Local Only")
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                }
            } header: {
                Text("Storage")
            } footer: {
                Text("All data is stored locally using SwiftData. No cloud storage is currently enabled.")
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCounts()
        }
    }

    private func loadCounts() {
        do {
            captureCount = try CaptureRepository(modelContext: modelContext).fetchAll().count
            planCount = try PlanRepository(modelContext: modelContext).fetchAll().count
            taskCount = try TaskRepository(modelContext: modelContext).fetchAll().count
            listCount = try ListRepository(modelContext: modelContext).fetchAllLists().count
            commCount = try CommunicationRepository(modelContext: modelContext).fetchAll().count
        } catch {
            AppLogger.persistence.error("Load storage counts failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))

                        Text("Offload")
                            .font(Theme.Typography.largeTitle)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(Theme.Typography.headline)

                        Text("Offload is an iOS-first app that turns quick thought captures (text or voice) into simple, organized plans and lists—tasks, shopping, and follow-ups—so you can get mental space back.")
                            .font(Theme.Typography.body)

                        Text("Most productivity tools assume you'll calmly plan everything up front. Offload starts where real life starts: random thoughts, urgency spikes, and \"I'll remember\" moments.")
                            .font(Theme.Typography.body)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Core Philosophy")
                            .font(Theme.Typography.headline)

                        PhilosophyItem(icon: "shield.checkered", text: "Psychological Safety: No guilt, no shame, no forced structure")
                        PhilosophyItem(icon: "wifi.slash", text: "Offline-First: Works completely offline, on-device processing")
                        PhilosophyItem(icon: "hand.raised", text: "User Control: AI suggests, never auto-modifies")
                        PhilosophyItem(icon: "lock.fill", text: "Privacy: All data stays on device, no cloud required")
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Open Source")
                            .font(Theme.Typography.headline)

                        Text("Offload is open source and available on GitHub. Contributions and feedback are welcome.")
                            .font(Theme.Typography.body)

                        Link(destination: Constants.githubURL) {
                            Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("License")
                            .font(Theme.Typography.headline)

                        Text("MIT License")
                            .font(Theme.Typography.body)

                        Text("Copyright © 2026 William Conklin")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PhilosophyItem: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                .frame(width: 24)

            Text(text)
                .font(Theme.Typography.body)
        }
    }
}

private struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Privacy Policy")
                        .font(Theme.Typography.largeTitle)
                        .fontWeight(.bold)

                    Text("Last Updated: January 5, 2026")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

                    Divider()

                    PolicySection(
                        title: "Data Collection",
                        content: "Offload does not collect, transmit, or store any personal data on external servers. All captures, plans, tasks, and other content are stored locally on your device using SwiftData."
                    )

                    PolicySection(
                        title: "Voice Recording",
                        content: "Voice recordings are processed entirely on your device using Apple's Speech Recognition framework. No audio data is transmitted to external servers. Transcriptions are stored locally with your captures."
                    )

                    PolicySection(
                        title: "AI Suggestions (Future)",
                        content: "When AI suggestions are enabled in a future update, anonymized capture text may be sent to our secure API for processing. You will be able to opt-in or opt-out at any time. Suggestions will never be stored permanently on external servers."
                    )

                    PolicySection(
                        title: "No Tracking",
                        content: "Offload does not use analytics, telemetry, or tracking tools. We don't know how you use the app, and we like it that way."
                    )

                    PolicySection(
                        title: "Your Rights",
                        content: "Since all data is stored locally on your device, you have complete control. You can delete any or all data at any time through the app or by deleting the app from your device."
                    )

                    PolicySection(
                        title: "Changes to This Policy",
                        content: "We may update this privacy policy from time to time. Significant changes will be communicated through the app or GitHub repository."
                    )

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Questions?")
                            .font(Theme.Typography.headline)

                        Text("If you have questions about this privacy policy, please open an issue on our GitHub repository.")
                            .font(Theme.Typography.body)

                        Link(destination: Constants.issuesURL) {
                            Label("Open an Issue", systemImage: "exclamationmark.bubble")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PolicySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Typography.headline)

            Text(content)
                .font(Theme.Typography.body)
        }
    }
}

private struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    let onSave: (String, String?) throws -> Void

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category name", text: $name)
                        .accessibilityLabel("Category name")
                    TextField("Emoji (optional)", text: $icon)
                        .accessibilityLabel("Category emoji")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Theme.Typography.errorText)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme, style: themeManager.currentStyle))
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityHint("Closes without saving")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityHint("Saves the category")
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)

            try onSave(
                trimmedName,
                trimmedIcon.isEmpty ? nil : trimmedIcon
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct TagFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    let onSave: (String, String?) throws -> Void

    @State private var name: String = ""
    @State private var color: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Tag name", text: $name)
                        .accessibilityLabel("Tag name")
                    TextField("Color (optional)", text: $color)
                        .accessibilityLabel("Tag color")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Theme.Typography.errorText)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme, style: themeManager.currentStyle))
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityHint("Closes without saving")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityHint("Saves the tag")
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedColor = color.trimmingCharacters(in: .whitespacesAndNewlines)

            try onSave(
                trimmedName,
                trimmedColor.isEmpty ? nil : trimmedColor
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
