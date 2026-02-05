// Purpose: Capture feature views and flows.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve low-friction capture UX and Item.type == nil semantics.

//  Flat design capture list with inline tagging and swipe actions

import OSLog
import SwiftData
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var errorPresenter = ErrorPresenter()
    @State private var viewModel = CaptureListViewModel()

    let navigationTitle: String
    @State private var showingSettings = false
    @State private var showingSearch = false
    @State private var searchQuery = ""
    @State private var selectedItem: Item?
    @State private var tagPickerItem: Item?
    @State private var moveItem: Item?
    @State private var moveDestination: MoveDestination?

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }

    init(navigationTitle: String = "Capture") {
        self.navigationTitle = navigationTitle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Vibrant gradient background
                Theme.Gradients.deepBackground(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        if viewModel.items.isEmpty, viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, Theme.Spacing.sm)
                        }

                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            ItemCard(
                                item: item,
                                colorScheme: colorScheme,
                                style: style,
                                onTap: { selectedItem = item },
                                onAddTag: { tagPickerItem = item },
                                onToggleStar: { toggleStar(item) },
                                onDelete: { deleteItem(item) },
                                onComplete: { completeItem(item) },
                                onMoveTo: { destination in
                                    moveItem = item
                                    moveDestination = destination
                                }
                            )
                            .onAppear {
                                if index == viewModel.items.count - 1 {
                                    loadNextPage()
                                }
                            }
                        }

                        if viewModel.isLoading, !viewModel.items.isEmpty {
                            ProgressView()
                                .padding(.vertical, Theme.Spacing.sm)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: floatingTabBarClearance)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        IconTile(
                            iconName: Icons.search,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Search")

                    Button {
                        showingSettings = true
                    } label: {
                        IconTile(
                            iconName: Icons.settings,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSearch) {
                CaptureSearchView(searchQuery: $searchQuery)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(themeManager)
            }
            .sheet(item: $selectedItem) { item in
                CaptureDetailView(item: item)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $tagPickerItem) { item in
                ItemTagPickerSheet(item: item)
                    .environmentObject(themeManager)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented:
                Binding(
                    get: { moveItem != nil && moveDestination == .plan },
                    set: { presented in
                        if !presented {
                            moveItem = nil
                            moveDestination = nil
                        }
                    }
                )
            ) {
                if let item = moveItem {
                    MoveToPlanSheet(item: item) {
                        moveItem = nil
                        moveDestination = nil
                        refreshItems()
                    }
                }
            }
            .sheet(isPresented:
                Binding(
                    get: { moveItem != nil && moveDestination == .list },
                    set: { presented in
                        if !presented {
                            moveItem = nil
                            moveDestination = nil
                        }
                    }
                )
            ) {
                if let item = moveItem {
                    MoveToListSheet(item: item) {
                        moveItem = nil
                        moveDestination = nil
                        refreshItems()
                    }
                }
            }
            .errorToasts(errorPresenter)
        }
        .onAppear {
            loadInitialIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .captureItemsChanged)) { _ in
            refreshItems()
        }
    }

    // MARK: - Actions

    private func deleteItem(_ item: Item) {
        let itemId = item.id
        AppLogger.workflow.info("CaptureView delete requested - id: \(itemId, privacy: .public)")
        do {
            try itemRepository.delete(item)
            viewModel.remove(item)
            AppLogger.workflow.info("CaptureView delete completed - id: \(itemId, privacy: .public)")
        } catch {
            AppLogger.workflow.error(
                "CaptureView delete failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            errorPresenter.present(error)
        }
    }

    private func completeItem(_ item: Item) {
        let itemId = item.id
        AppLogger.workflow.info("CaptureView complete requested - id: \(itemId, privacy: .public)")
        do {
            try itemRepository.complete(item)
            viewModel.remove(item)
            AppLogger.workflow.info("CaptureView complete completed - id: \(itemId, privacy: .public)")
        } catch {
            AppLogger.workflow.error(
                "CaptureView complete failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            errorPresenter.present(error)
        }
    }

    private func toggleStar(_ item: Item) {
        let itemId = item.id
        AppLogger.workflow.info("CaptureView star toggle requested - id: \(itemId, privacy: .public)")
        do {
            try itemRepository.toggleStar(item)
            AppLogger.workflow.info("CaptureView star toggle completed - id: \(itemId, privacy: .public)")
        } catch {
            AppLogger.workflow.error(
                "CaptureView star toggle failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            errorPresenter.present(error)
        }
    }

    private func loadInitialIfNeeded() {
        guard !viewModel.hasLoaded else { return }
        do {
            try viewModel.loadInitial(using: itemRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func loadNextPage() {
        do {
            try viewModel.loadNextPage(using: itemRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func refreshItems() {
        do {
            try viewModel.refresh(using: itemRepository)
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Move Destination

enum MoveDestination {
    case plan
    case list
}

// MARK: - Item Card

private struct ItemCard: View {
    let item: Item
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onToggleStar: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void
    let onMoveTo: (MoveDestination) -> Void

    @State private var offset: CGFloat = 0
    @State private var crtFlickerOpacity: Double = 1

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
            MCMCardContent(
                icon: item.itemType?.icon,
                title: item.content,
                typeLabel: item.type?.uppercased(),
                timestamp: item.relativeTimestamp,
                image: item.attachmentData.flatMap { UIImage(data: $0) },
                tags: item.tags,
                onAddTag: onAddTag,
                size: .compact // Compact size for item cards
            )
        }
        .overlay(alignment: .bottomTrailing) {
            StarButton(isStarred: item.isStarred, action: onToggleStar)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .overlay(
            // Swipe indicators
            HStack {
                if offset > 0 {
                    AppIcon(name: Icons.checkCircleFilled, size: 18)
                        .foregroundStyle(Theme.Colors.terminalGreen(colorScheme, style: style))
                        .padding(.leading, Theme.Spacing.md)
                        .opacity(min(1, Double(offset / 120)))
                }

                Spacer()

                if offset < 0 {
                    AppIcon(name: Icons.deleteFilled, size: 18)
                        .foregroundStyle(Theme.Colors.destructive(colorScheme, style: style))
                        .padding(.trailing, Theme.Spacing.md)
                        .opacity(min(1, Double(-offset / 120)))
                }
            }
        )
        .offset(x: offset)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    offset = dx
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else {
                        offset = 0
                        return
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if dx > 100 {
                            offset = 0
                            onComplete()
                        } else if dx < -100 {
                            offset = 0
                            onDelete()
                        } else {
                            offset = 0
                        }
                    }
                }
        )
        .contextMenu {
            Button {
                onMoveTo(.plan)
            } label: {
                Label {
                    Text("Move to Plan")
                } icon: {
                    AppIcon(name: Icons.plans, size: 14)
                }
            }

            Button {
                onMoveTo(.list)
            } label: {
                Label {
                    Text("Move to List")
                } icon: {
                    AppIcon(name: Icons.lists, size: 14)
                }
            }
        }
    }
}

// MARK: - Item Edit View

private struct CaptureDetailView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @State private var errorPresenter = ErrorPresenter()
    @State private var content: String

    init(item: Item) {
        self.item = item
        _content = State(initialValue: item.content)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Capture Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try itemRepository.updateContent(item, content: content)
                            dismiss()
                        } catch {
                            errorPresenter.present(error)
                        }
                    }
                }
            }
        }
        .errorToasts(errorPresenter)
    }
}

// MARK: - Move to Plan Sheet

private struct MoveToPlanSheet: View {
    let item: Item
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newPlanName = ""
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !collections.isEmpty {
                    Section("Select Plan") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelectedPlan()
                            } label: {
                                Text(collection.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label {
                            Text("Create New Plan")
                        } icon: {
                            AppIcon(name: Icons.addCircleFilled, size: 16)
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New Plan", isPresented: $createNew) {
                TextField("Plan name", text: $newPlanName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewPlanAndMove()
                }
            } message: {
                Text("Enter a name for the new plan")
            }
            .onAppear {
                loadCollections()
            }
        }
        .errorToasts(errorPresenter)
    }

    private func loadCollections() {
        do {
            collections = try collectionRepository.fetchStructured()
        } catch {
            errorPresenter.present(error)
            collections = []
        }
    }

    private func moveToSelectedPlan() {
        guard let collection = selectedCollection else { return }

        do {
            // Update item type
            try itemRepository.updateType(item, type: "task")

            // Link to collection
            let position = collection.collectionItems?.count ?? 0
            try itemRepository.moveToCollection(item, collection: collection, position: position)

            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func createNewPlanAndMove() {
        let trimmed = newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            // Create collection
            let collection = try collectionRepository.create(name: trimmed, isStructured: true)

            // Update item type
            try itemRepository.updateType(item, type: "task")

            // Link to collection
            try itemRepository.moveToCollection(item, collection: collection, position: 0)

            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Move to List Sheet

private struct MoveToListSheet: View {
    let item: Item
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newListName = ""
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !collections.isEmpty {
                    Section("Select List") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelectedList()
                            } label: {
                                Text(collection.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label {
                            Text("Create New List")
                        } icon: {
                            AppIcon(name: Icons.addCircleFilled, size: 16)
                        }
                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New List", isPresented: $createNew) {
                TextField("List name", text: $newListName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewListAndMove()
                }
            } message: {
                Text("Enter a name for the new list")
            }
            .onAppear {
                loadCollections()
            }
        }
        .errorToasts(errorPresenter)
    }

    private func loadCollections() {
        do {
            collections = try collectionRepository.fetchUnstructured()
        } catch {
            errorPresenter.present(error)
            collections = []
        }
    }

    private func moveToSelectedList() {
        guard let collection = selectedCollection else { return }

        do {
            // Update item type
            try itemRepository.updateType(item, type: "task")

            // Link to collection (no position for unstructured lists)
            try itemRepository.moveToCollection(item, collection: collection, position: nil)

            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func createNewListAndMove() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            // Create collection
            let collection = try collectionRepository.create(name: trimmed, isStructured: false)

            // Update item type
            try itemRepository.updateType(item, type: "task")

            // Link to collection
            try itemRepository.moveToCollection(item, collection: collection, position: nil)

            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Capture Search View

private struct CaptureSearchView: View {
    @Binding var searchQuery: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchResults: [Item] = []
    @State private var matchingTags: [Tag] = []
    @State private var selectedTags: Set<UUID> = []
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
            return
        }

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

#Preview {
    CaptureView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
