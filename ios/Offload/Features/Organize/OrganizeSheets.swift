// Purpose: Sheet and search views for OrganizeView.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftData
import SwiftUI

// MARK: - Form Sheet

struct CollectionFormSheet: View {
    let isStructured: Bool
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(isStructured ? "Plan name" : "List name", text: $name)
            }
            .navigationTitle(isStructured ? "New Plan" : "New List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Collection Tag Picker Sheet

struct CollectionTagPickerSheet: View {
    let collection: Collection

    @Environment(\.dismiss) private var dismiss
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var newTagName = ""
    @State private var errorPresenter = ErrorPresenter()
    @FocusState private var focused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                Section("Create New Tag") {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                            .focused($focused)
                        Button("Add") {
                            createTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Select Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if collection.tags.contains(where: { $0.id == tag.id }) {
                                    AppIcon(name: Icons.check, size: 12)
                                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .errorToasts(errorPresenter)
    }

    private func createTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let tag = try tagRepository.fetchOrCreate(trimmed)
            try collectionRepository.addTag(collection, tag: tag)
            newTagName = ""
        } catch {
            errorPresenter.present(error)
        }
    }

    private func toggleTag(_ tag: Tag) {
        do {
            if collection.tags.contains(where: { $0.id == tag.id }) {
                try collectionRepository.removeTag(collection, tag: tag)
            } else {
                try collectionRepository.addTag(collection, tag: tag)
            }
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Organize Search View

struct OrganizeSearchView: View {
    @Binding var searchQuery: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchResults: [Collection] = []
    @State private var matchingTags: [Tag] = []
    @State private var selectedTags: Set<UUID> = []
    @State private var isSearching = false
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.deepBackground(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.xs) {
                            AppIcon(name: Icons.search, size: 16)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                            TextField("Search collections...", text: $searchQuery)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if !searchQuery.isEmpty {
                                Button {
                                    searchQuery = ""
                                    searchResults = []
                                } label: {
                                    AppIcon(name: Icons.closeCircleFilled, size: 16)
                                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)
                                .fill(Theme.Colors.surface(colorScheme, style: style))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)
                                        .stroke(
                                            Theme.Colors.borderMuted(colorScheme, style: style)
                                                .opacity(Theme.Opacity.borderMuted(colorScheme)),
                                            lineWidth: 0.6
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)

                    // Tag chips
                    if !matchingTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.xs) {
                                ForEach(matchingTags) { tag in
                                    Button {
                                        toggleTagSelection(tag)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(tag.name)
                                                .font(Theme.Typography.caption)
                                            if selectedTags.contains(tag.id) {
                                                AppIcon(name: Icons.closeCircleFilled, size: 12)
                                            }
                                        }
                                        .foregroundStyle(
                                            selectedTags.contains(tag.id)
                                                ? Theme.Colors.cardTextPrimary(colorScheme, style: style)
                                                : Theme.Colors.textSecondary(colorScheme, style: style)
                                        )
                                        .padding(.horizontal, Theme.Spacing.pillHorizontal)
                                        .padding(.vertical, Theme.Spacing.pillVertical)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    selectedTags.contains(tag.id)
                                                        ? (tag.color.flatMap { Color(hex: $0) } ?? Theme.Colors.tagColor(for: tag.name, colorScheme, style: style))
                                                        : Theme.Colors.surface(colorScheme, style: style)
                                                )
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedTags.contains(tag.id)
                                                        ? Color.clear
                                                        : Theme.Colors.borderMuted(colorScheme, style: style),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                        .padding(.bottom, Theme.Spacing.sm)
                    }
                    // Results
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            if searchQuery.isEmpty {
                                emptyQueryState
                            } else if isSearching {
                                ProgressView()
                                    .padding(.vertical, Theme.Spacing.xl)
                            } else if searchResults.isEmpty {
                                noResultsState
                            } else {
                                resultsContent
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Search Collections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                performSearch(newValue)
            }
            .errorToasts(errorPresenter)
        }
    }

    @ViewBuilder
    private var emptyQueryState: some View {
        EmptyStateView(
            iconName: Icons.search,
            message: "Start typing to search collections"
        )
    }

    @ViewBuilder
    private var noResultsState: some View {
        EmptyStateView(
            iconName: Icons.search,
            message: "No collections found",
            subtitle: "Try a different search term"
        )
    }

    @ViewBuilder
    private var resultsContent: some View {
        ForEach(Array(searchResults.enumerated()), id: \.element.id) { _, collection in
            NavigationLink {
                CollectionDetailView(collectionID: collection.id)
                    .environmentObject(themeManager)
            } label: {
                CardSurface(fill: Theme.Colors.cardColor(index: collection.stableColorIndex, colorScheme, style: style)) {
                    MCMCardContent(
                        icon: collection.isStructured ? Icons.plans : Icons.lists,
                        title: collection.name,
                        typeLabel: collection.isStructured ? "PLAN" : "LIST",
                        timestamp: collection.formattedDate,
                        tags: collection.tags,
                        onAddTag: nil,
                        size: .standard
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            matchingTags = []
            selectedTags.removeAll()
            isSearching = false
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            // Search for matching tags
            matchingTags = try tagRepository.searchByName(query)

            // If tags are selected, show ALL collections with those tags (not just matching search text)
            if !selectedTags.isEmpty {
                // Get all collections that have the selected tags
                let allCollections = try collectionRepository.fetchAll()
                let taggedCollections = allCollections.filter { collection in
                    selectedTags.contains { tagId in
                        collection.tags.contains(where: { $0.id == tagId })
                    }
                }
                // Don't combine with name search - just show tagged collections
                searchResults = taggedCollections.sorted { $0.createdAt > $1.createdAt }
            } else {
                // No tags selected, just show name search results
                searchResults = try collectionRepository.searchByName(query)
            }
        } catch {
            errorPresenter.present(error)
            searchResults = []
            matchingTags = []
        }
    }

    private func toggleTagSelection(_ tag: Tag) {
        if selectedTags.contains(tag.id) {
            selectedTags.remove(tag.id)
        } else {
            selectedTags.insert(tag.id)
        }

        // Re-run search with updated filters
        performSearch(searchQuery)
    }
}
