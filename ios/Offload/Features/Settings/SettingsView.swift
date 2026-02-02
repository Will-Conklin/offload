// Purpose: Settings and account feature views.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Avoid introducing feature logic that belongs in repositories.

//  Simple flat settings: theme picker, tags/categories, basic info

import SwiftUI
import SwiftData


struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                // Appearance section
                Section {
                    Picker("Appearance", selection: $themeManager.appearancePreference) {
                        ForEach(AppearancePreference.allCases) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                    .pickerStyle(.menu)
                    .rowStyle(.card)
                } header: {
                    Text("Appearance")
                }

                // Tags section
                Section {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            IconTile(
                                iconName: Icons.tag,
                                iconSize: 16,
                                tileSize: 32,
                                style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                            )
                            Text("Tags")
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            Spacer()
                        }
                    }
                    .rowStyle(.card)
                } header: {
                    Text("Tags")
                }

                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    .rowStyle(.card)

                    Link(destination: URL(string: "https://github.com/Will-Conklin/offload")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            AppIcon(name: Icons.externalLink, size: 12)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }
                    .rowStyle(.card)
                } header: {
                    Text("About")
                }
            }
            .listSectionSpacing(Theme.Spacing.lgSoft)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - Tag Management

private struct TagManagementView: View {
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var showingAddTag = false
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        List {
            Section {
                ForEach(tags) { tag in
                    HStack(spacing: Theme.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.Colors.tagColor(for: tag.name, colorScheme, style: style))
                            .frame(width: 12, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(
                                        Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.45),
                                        lineWidth: 0.6
                                    )
                            )

                        Text(tag.name)
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                        Spacer()
                    }
                    .rowStyle(.card)
                }
                .onDelete(perform: deleteTags)

                Button {
                    showingAddTag = true
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        IconTile(
                            iconName: Icons.add,
                            iconSize: 16,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                        Text("Add Tag")
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        Spacer()
                    }
                }
                .rowStyle(.card)
            } header: {
                Text("Tags")
            }
        }
        .listSectionSpacing(Theme.Spacing.lgSoft)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background(colorScheme, style: style))
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddTag) {
            AddTagSheet()
        }
        .errorToasts(errorPresenter)
    }

    private func deleteTags(offsets: IndexSet) {
        for index in offsets {
            do {
                try tagRepository.delete(tag: tags[index])
            } catch {
                errorPresenter.present(error)
            }
        }
    }
}

// MARK: - Add Tag Sheet

private struct AddTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Tag name", text: $name)
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .toolbarBackground(Theme.Colors.background(colorScheme, style: style), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        do {
                            _ = try tagRepository.fetchOrCreate(trimmed)
                            dismiss()
                        } catch {
                            errorPresenter.present(error)
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .errorToasts(errorPresenter)
    }
}

#Preview {
    SettingsView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
