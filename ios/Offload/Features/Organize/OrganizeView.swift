// Purpose: Organize feature views and flows.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep collection ordering aligned with Collection.sortedItems and CollectionItem.position.

//  Simplified design for Plans and Lists tabs using Collections

import OSLog
import SwiftData
import SwiftUI

struct OrganizeView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case plans, lists

        var id: String { rawValue }

        var title: String {
            switch self {
            case .plans: "Plans"
            case .lists: "Lists"
            }
        }

        var isStructured: Bool {
            switch self {
            case .plans: true
            case .lists: false
            }
        }
    }

    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @AppStorage("organize.scope") private var selectedScopeRaw = Scope.plans.rawValue
    @State private var showingCreate = false
    @State private var showingSettings = false
    @State private var selectedCollection: Collection?
    @State private var tagPickerCollection: Collection?
    @State private var errorPresenter = ErrorPresenter()
    @State private var viewModel = OrganizeListViewModel()
    @State private var showingSearch = false
    @State private var searchQuery = ""

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }

    private var selectedScope: Scope {
        Scope(rawValue: selectedScopeRaw) ?? .plans
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Vibrant gradient background
                Theme.Gradients.deepBackground(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        scopePicker
                            .padding(.top, Theme.Spacing.sm)

                        collectionsContent
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: floatingTabBarClearance)
                }
            }
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: {
                        IconTile(
                            iconName: Icons.addCircleFilled,
                            iconSize: 18,
                            tileSize: 44,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Add \(selectedScope == .plans ? "Plan" : "List")")

                    Button {
                        showingSearch = true
                    } label: {
                        IconTile(
                            iconName: Icons.search,
                            iconSize: 18,
                            tileSize: 44,
                            style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Search")

                    Button { showingSettings = true } label: {
                        IconTile(
                            iconName: Icons.settings,
                            iconSize: 18,
                            tileSize: 44,
                            style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingCreate, onDismiss: refreshCollections) {
                createSheet
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingSearch) {
                OrganizeSearchView(searchQuery: $searchQuery)
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $tagPickerCollection) { collection in
                CollectionTagPickerSheet(collection: collection)
                    .environmentObject(themeManager)
                    .presentationDetents([.medium])
            }
            .navigationDestination(item: $selectedCollection) { collection in
                CollectionDetailView(collectionID: collection.id)
                    .environmentObject(themeManager)
            }
            .errorToasts(errorPresenter)
        }
        .onAppear {
            loadScopeIfNeeded()
        }
        .onChange(of: selectedScopeRaw) { _, _ in
            updateScope()
        }
    }

    // MARK: - Collections Content

    @ViewBuilder
    private var collectionsContent: some View {
        if viewModel.collections.isEmpty {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                emptyState
            }
        } else {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) { index, collection in
                DraggableCollectionCard(
                    collection: collection,
                    colorScheme: colorScheme,
                    style: style,
                    onTap: { selectedCollection = collection },
                    onAddTag: { tagPickerCollection = collection },
                    onToggleStar: { toggleStar(collection) },
                    onDrop: { droppedId, targetId in
                        handleCollectionReorder(droppedId: droppedId, targetId: targetId)
                    },
                    onMoveUp: index > 0 ? {
                        let targetId = viewModel.collections[index - 1].id
                        handleCollectionReorder(droppedId: collection.id, targetId: targetId)
                    } : nil,
                    onMoveDown: index < viewModel.collections.count - 1 ? {
                        let targetId = viewModel.collections[index + 1].id
                        handleCollectionReorder(droppedId: collection.id, targetId: targetId)
                    } : nil
                )
                .onAppear {
                    if index == viewModel.collections.count - 1 {
                        loadNextPage()
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.sm)
            }

            if !viewModel.collections.isEmpty {
                BottomCollectionDropZone(
                    colorScheme: colorScheme,
                    style: style,
                    onDrop: { droppedId in
                        handleCollectionDropAtEnd(droppedId: droppedId)
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            iconName: selectedScope == .plans ? Icons.plans : Icons.lists,
            message: "No \(selectedScope.title.lowercased()) yet",
            actionTitle: "Add \(selectedScope == .plans ? "Plan" : "List")",
            action: { showingCreate = true }
        )
    }

    // MARK: - Scope Picker

    private var scopePicker: some View {
        let fill = Theme.Colors.surface(colorScheme, style: style)

        return HStack(spacing: Theme.Spacing.xs) {
            scopeButton(.plans)
            scopeButton(.lists)
        }
        .padding(Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)
                        .stroke(
                            Theme.Colors.borderMuted(colorScheme, style: style)
                                .opacity(Theme.Opacity.borderMuted(colorScheme)),
                            lineWidth: 0.6
                        )
                )
        )
        .shadow(
            color: Theme.Shadows.ultraLight(colorScheme),
            radius: Theme.Shadows.elevationUltraLight,
            y: Theme.Shadows.offsetYUltraLight
        )
    }

    private func scopeButton(_ scope: Scope) -> some View {
        Button {
            selectedScopeRaw = scope.rawValue
        } label: {
            Text(scope.title)
                .font(selectedScope == scope ? Theme.Typography.subheadlineSemibold : Theme.Typography.subheadline)
                .foregroundStyle(
                    selectedScope == scope
                        ? Theme.Colors.cardTextPrimary(colorScheme, style: style)
                        : Theme.Colors.textSecondary(colorScheme, style: style)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    selectedScope == scope
                        ? Theme.Surface.card(colorScheme, style: style)
                        : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create Sheet

    @ViewBuilder
    private var createSheet: some View {
        CollectionFormSheet(isStructured: selectedScope.isStructured) { name in
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                errorPresenter.present(ValidationError("Collection name cannot be empty."))
                return
            }
            do {
                _ = try collectionRepository.create(
                    name: trimmedName,
                    isStructured: selectedScope.isStructured
                )
            } catch {
                errorPresenter.present(error)
            }
        }
    }

    private func toggleStar(_ collection: Collection) {
        do {
            try collectionRepository.toggleStar(collection)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func loadScopeIfNeeded() {
        guard !viewModel.hasLoaded else { return }
        // Backfill positions for existing collections
        do {
            try collectionRepository.backfillCollectionPositions(isStructured: selectedScope.isStructured)
        } catch {
            AppLogger.general.error("Failed to backfill collection positions: \(error.localizedDescription)")
        }
        updateScope()
    }

    private func updateScope() {
        do {
            // Backfill positions when switching scopes
            try collectionRepository.backfillCollectionPositions(isStructured: selectedScope.isStructured)
            try viewModel.setScope(isStructured: selectedScope.isStructured, using: collectionRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func loadNextPage() {
        do {
            try viewModel.loadNextPage(using: collectionRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func refreshCollections() {
        do {
            try viewModel.refresh(using: collectionRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func handleCollectionReorder(droppedId: UUID, targetId: UUID) {
        AppLogger.general.info("Collection reorder: \(droppedId) to position of \(targetId)")

        do {
            // Find the dropped and target collections
            guard let droppedIndex = viewModel.collections.firstIndex(where: { $0.id == droppedId }),
                  let targetIndex = viewModel.collections.firstIndex(where: { $0.id == targetId })
            else {
                AppLogger.general.error("Could not find dropped or target collection")
                return
            }

            // Reorder in view model
            let droppedCollection = viewModel.collections[droppedIndex]
            var newCollections = viewModel.collections
            newCollections.remove(at: droppedIndex)

            // Adjust target index if item was removed before target position
            let adjustedTargetIndex = droppedIndex < targetIndex ? targetIndex - 1 : targetIndex
            newCollections.insert(droppedCollection, at: adjustedTargetIndex)

            // Update all positions
            for (index, collection) in newCollections.enumerated() {
                collection.position = index
            }

            try collectionRepository.reorderCollections(newCollections)
            AppLogger.general.info("Collections reordered successfully")

            // Refresh to show new order
            refreshCollections()
        } catch {
            AppLogger.general.error("Failed to handle collection reorder: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }

    private func handleCollectionDropAtEnd(droppedId: UUID) {
        AppLogger.general.info("Collection drop at end: \(droppedId)")

        do {
            guard let droppedCollection = viewModel.collections.first(where: { $0.id == droppedId }) else {
                AppLogger.general.error("Could not find dropped collection")
                return
            }

            // Remove from current position
            var newCollections = viewModel.collections.filter { $0.id != droppedId }
            // Add to end
            newCollections.append(droppedCollection)

            // Update all positions
            for (index, collection) in newCollections.enumerated() {
                collection.position = index
            }

            try collectionRepository.reorderCollections(newCollections)
            AppLogger.general.info("Collection moved to end successfully")

            // Refresh to show new order
            refreshCollections()
        } catch {
            AppLogger.general.error("Failed to handle collection drop at end: \(error.localizedDescription)")
            errorPresenter.present(error)
        }
    }
}

// MARK: - Draggable Collection Card

private struct DraggableCollectionCard: View {
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onToggleStar: () -> Void
    let onDrop: (UUID, UUID) -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        Button {
            onTap()
        } label: {
            CollectionCard(
                collection: collection,
                colorScheme: colorScheme,
                style: style,
                onAddTag: onAddTag,
                onToggleStar: onToggleStar
            )
        }
        .buttonStyle(.plain)
        .draggable(collection.id.uuidString) {
            // Preview while dragging
            Text(collection.name)
                .font(Theme.Typography.caption)
                .lineLimit(2)
                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                .padding(Theme.Spacing.sm)
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(Theme.Colors.cardColor(index: collection.stableColorIndex, colorScheme, style: style))
                )
        }
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let droppedIdString = droppedIds.first,
                  let droppedId = UUID(uuidString: droppedIdString)
            else {
                return false
            }

            // Prevent dropping on self
            if droppedId == collection.id {
                return false
            }

            onDrop(droppedId, collection.id)
            return true
        } isTargeted: { isTargeted in
            withAnimation(reduceMotion ? .default : .easeInOut(duration: 0.2)) {
                isDropTarget = isTargeted
            }
        }
        .overlay(alignment: .top) {
            // Show insertion line when dropping
            if isDropTarget {
                Rectangle()
                    .fill(Theme.Colors.primary(colorScheme, style: style))
                    .frame(height: 3)
                    .offset(y: -(Theme.Spacing.md / 2 + 1.5))
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .default : .easeInOut(duration: 0.2), value: isDropTarget)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Move up") {
            onMoveUp?()
        }
        .accessibilityAction(named: "Move down") {
            onMoveDown?()
        }
    }
}

// MARK: - Bottom Collection Drop Zone

private struct BottomCollectionDropZone: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onDrop: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
            .fill(isDropTarget
                ? Theme.Colors.primary(colorScheme, style: style).opacity(0.08)
                : Color.white.opacity(0.001)
            )
            .frame(height: isDropTarget ? 60 : 44)
            .overlay {
                if isDropTarget {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .strokeBorder(
                            Theme.Colors.primary(colorScheme, style: style),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                        )
                }
            }
            .dropDestination(for: String.self) { droppedIds, _ in
                guard let droppedIdString = droppedIds.first,
                      let droppedId = UUID(uuidString: droppedIdString)
                else {
                    return false
                }

                onDrop(droppedId)
                return true
            } isTargeted: { isTargeted in
                withAnimation(reduceMotion ? .default : .easeInOut(duration: 0.2)) {
                    isDropTarget = isTargeted
                }
            }
    }
}

// MARK: - Collection Card

private struct CollectionCard: View {
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onAddTag: () -> Void
    let onToggleStar: () -> Void

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: collection.stableColorIndex, colorScheme, style: style)) {
            // MCM card content with custom metadata for collections
            HStack(alignment: .top, spacing: 0) {
                // Left column (narrow - metadata gutter)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    IconTile(
                        iconName: collection.isStructured ? Icons.plans : Icons.lists,
                        iconSize: 16,
                        tileSize: 36,
                        style: .none(Theme.Colors.icon(colorScheme, style: style))
                    )

                    Text(collection.isStructured ? "PLAN" : "LIST")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                    Text(collection.formattedDate)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                    if let count = collection.collectionItems?.count, count > 0 {
                        Text("\(count) item\(count == 1 ? "" : "s")")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                }
                .frame(width: 60, alignment: .leading)

                // Right column (wide - main content)
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(collection.name)
                        .font(.system(.title2, design: .default).weight(.bold))
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        .lineLimit(3)

                    // Tags in flow layout
                    if !collection.tags.isEmpty {
                        FlowLayout(spacing: Theme.Spacing.xs) {
                            ForEach(collection.tags) { tag in
                                TagPill(
                                    name: tag.name,
                                    color: tag.color
                                        .map { Color(hex: $0) }
                                        ?? Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                )
                            }

                            Button(action: onAddTag) {
                                HStack(spacing: 4) {
                                    AppIcon(name: Icons.add, size: 10)
                                    Text("Tag")
                                        .font(Theme.Typography.caption)
                                }
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                                .padding(.horizontal, Theme.Spacing.pillHorizontal)
                                .padding(.vertical, Theme.Spacing.pillVertical)
                                .background(
                                    Capsule()
                                        .strokeBorder(
                                            Theme.Colors.borderMuted(colorScheme, style: style),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, 12)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            StarButton(isStarred: collection.isStarred, action: onToggleStar)
        }
    }
}

// MARK: - Form Sheet

private struct CollectionFormSheet: View {
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

private struct CollectionTagPickerSheet: View {
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

private struct OrganizeSearchView: View {
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

#Preview {
    OrganizeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
