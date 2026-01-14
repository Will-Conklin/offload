//
//  SettingsView.swift
//  Offload
//
//  Simple flat settings: theme picker, tags/categories, basic info
//

import SwiftUI
import SwiftData

// AGENT NAV
// - Layout
// - Tags
// - About
// - Add Tag Sheet

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var showingAddTag = false

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                // Theme section
                Section {
                    Picker("Theme", selection: $themeManager.currentStyle) {
                        ForEach(ThemeStyle.allCases, id: \.self) { theme in
                            HStack {
                                Circle()
                                    .fill(Theme.Colors.primary(colorScheme, style: theme))
                                    .frame(width: 20, height: 20)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Theme applies to both light and dark modes")
                }

                // Tags section
                Section {
                    ForEach(tags) { tag in
                        HStack {
                            Text(tag.name)
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteTags)

                    Button {
                        showingAddTag = true
                    } label: {
                        Label {
                            Text("Add Tag")
                        } icon: {
                            AppIcon(name: Icons.addCircle, size: 16)
                        }
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Tags help organize captures and tasks")
                }

                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }

                    Link(destination: URL(string: "https://github.com/Will-Conklin/offload")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            AppIcon(name: Icons.externalLink, size: 12)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                AddTagSheet(modelContext: modelContext)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func deleteTags(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}

// MARK: - Add Tag Sheet

private struct AddTagSheet: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Tag name", text: $name)
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        let tag = Tag(name: trimmed)
                        modelContext.insert(tag)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Theme Display Name Extension

extension ThemeStyle {
    var displayName: String {
        switch self {
        case .oceanTeal: return "Ocean Teal"
        case .violetPop: return "Violet Pop"
        case .sunsetCoral: return "Sunset Coral"
        case .slate: return "Slate"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
