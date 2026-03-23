// Purpose: Tag management views extracted for reuse across settings and account features.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Avoid introducing feature logic that belongs in repositories.

import SwiftData
import SwiftUI

// MARK: - Tag Management

struct TagManagementView: View {
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var showingAddTag = false
    @State private var errorPresenter = ErrorPresenter()
    @State private var tagToDelete: Tag?
    @State private var showDeleteConfirmation = false

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        List {
            Section {
                ForEach(tags) { tag in
                    HStack(spacing: Theme.Spacing.sm) {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.iconTile, style: .continuous)
                            .fill(Theme.Colors.tagColor(for: tag.name, colorScheme, style: style))
                            .frame(width: 12, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.iconTile, style: .continuous)
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
                .onDelete { offsets in
                    if let index = offsets.first {
                        tagToDelete = tags[index]
                        showDeleteConfirmation = true
                    }
                }

                Button {
                    showingAddTag = true
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        IconTile(
                            iconName: Icons.add,
                            iconSize: 16,
                            tileSize: 44,
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
        .confirmationDialog(
            "Delete this tag? This cannot be undone.",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Tag", role: .destructive) {
                if let tag = tagToDelete {
                    do {
                        try tagRepository.delete(tag: tag)
                    } catch {
                        errorPresenter.present(error)
                    }
                }
                tagToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tagToDelete = nil
            }
        }
        .errorToasts(errorPresenter)
    }
}

// MARK: - Add Tag Sheet

struct AddTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Tag Name")
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

                        TextField("Tag name", text: $name)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                            .focused($isFocused)
                    }
                }
                .padding(Theme.Spacing.md)

                Spacer()
            }
            .background(Theme.Gradients.deepBackground(colorScheme).ignoresSafeArea())
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
            .onAppear { isFocused = true }
        }
        .errorToasts(errorPresenter)
    }
}
