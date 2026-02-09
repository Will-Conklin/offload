// Purpose: Search view for CaptureView.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI
import UIKit

// MARK: - Capture Search View

struct CaptureSearchView: View {
    @Binding var searchQuery: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchResults: [Item] = []
    @State private var matchingTags: [Tag] = []
    @State private var selectedTags: Set<UUID> = []
    @State private var isSearching = false
    @State private var errorPresenter = ErrorPresenter()
    @FocusState private var isSearchFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.deepBackground(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.sm) {
                            AppIcon(name: Icons.search, size: 16)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                            TextField("Search captures...", text: $searchQuery)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                .focused($isSearchFocused)
                                .onChange(of: searchQuery) { _, newValue in
                                    performSearch(newValue)
                                }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface(colorScheme, style: style))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                                searchResults = []
                            } label: {
                                AppIcon(name: Icons.closeCircleFilled, size: 20)
                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.md)

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
                    if searchQuery.isEmpty {
                        Spacer()
                        VStack(spacing: Theme.Spacing.sm) {
                            AppIcon(name: Icons.search, size: 48)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style).opacity(0.5))
                            Text("Search your captures")
                                .font(Theme.Typography.title3)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                        Spacer()
                    } else if isSearching {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if searchResults.isEmpty {
                        EmptyStateView(
                            iconName: Icons.search,
                            message: "No results found"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.md) {
                                ForEach(Array(searchResults.enumerated()), id: \.element.id) { _, item in
                                    CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
                                        MCMCardContent(
                                            icon: item.itemType?.icon,
                                            title: item.content,
                                            typeLabel: item.type?.uppercased(),
                                            timestamp: item.relativeTimestamp,
                                            image: item.attachmentData.flatMap { UIImage(data: $0) },
                                            tags: item.tags,
                                            onAddTag: {},
                                            size: .compact
                                        )
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.bottom, Theme.Spacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
        .errorToasts(errorPresenter)
    }

    private func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
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
            matchingTags = try tagRepository.searchByName(trimmed)

            // If tags are selected, show ALL items with those tags (not just matching search text)
            if !selectedTags.isEmpty {
                var taggedItems: [Item] = []
                for tagId in selectedTags {
                    // Fetch tag directly by ID to get all items, not just those matching search
                    if let tag = try tagRepository.fetchById(tagId) {
                        try taggedItems.append(contentsOf: itemRepository.fetchByTag(tag))
                    }
                }
                // Don't combine with text search - just show tagged items
                searchResults = Array(Set(taggedItems)).sorted { $0.createdAt > $1.createdAt }
            } else {
                // No tags selected, just show text search results
                searchResults = try itemRepository.searchByContent(trimmed)
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
