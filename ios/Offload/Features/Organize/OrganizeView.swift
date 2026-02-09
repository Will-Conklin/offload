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
    @State private var collectionToConvert: Collection?
    @State private var showConversionConfirmation = false

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
            .confirmationDialog(
                "This will flatten the plan's hierarchy. All items will be preserved but parent-child relationships will be lost.",
                isPresented: $showConversionConfirmation,
                titleVisibility: .visible
            ) {
                Button("Convert to List", role: .destructive) {
                    if let collection = collectionToConvert {
                        performConversion(collection)
                    }
                }
                Button("Cancel", role: .cancel) {
                    collectionToConvert = nil
                }
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
                .contextMenu {
                    Button {
                        handleConvert(collection)
                    } label: {
                        Label(
                            collection.isStructured ? "Convert to List" : "Convert to Plan",
                            systemImage: collection.isStructured ? Icons.lists : Icons.plans
                        )
                    }
                }
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

    private func handleConvert(_ collection: Collection) {
        // If converting from plan to list, show confirmation
        if collection.isStructured {
            collectionToConvert = collection
            showConversionConfirmation = true
        } else {
            // List to plan conversion is non-destructive, proceed directly
            performConversion(collection)
        }
    }

    private func performConversion(_ collection: Collection) {
        do {
            let newStructure = !collection.isStructured
            try collectionRepository.convertCollection(collection, toStructured: newStructure)
            refreshCollections()
            collectionToConvert = nil
        } catch {
            errorPresenter.present(error)
            collectionToConvert = nil
        }
    }
}

#Preview {
    OrganizeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
