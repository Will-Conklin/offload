// Purpose: Capture feature views and flows.
// Authority: Code-level
// Governed by: CLAUDE.md
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
    @Environment(ToastManager.self) private var toastManager
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
    @State private var breakdownItem: Item?
    @State private var brainDumpItem: Item?
    @State private var decisionFatigueItem: Item?
    @State private var execFunctionItem: Item?
    @State private var draftItem: Item?
    @State private var quickCaptureText: String = ""
    @State private var itemToDelete: Item?
    @State private var showDeleteConfirmation = false

    private var style: ThemeStyle { themeManager.currentStyle }
    /// Extra clearance for the OffloadCTA button that lifts above the floating tab bar.
    private var ctaClearance: CGFloat { Theme.Spacing.xl + Theme.Spacing.lg }
    private var isQuickCaptureEmpty: Bool { quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isQuickCaptureAtLimit: Bool { quickCaptureText.count >= PendingCaptureStore.maxContentLength }

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
                        typeFilterBar
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.xs)

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
                                onDelete: {
                                    itemToDelete = item
                                    showDeleteConfirmation = true
                                },
                                onComplete: { completeItem(item) },
                                onMoveTo: { destination in
                                    moveItem = item
                                    moveDestination = destination
                                },
                                onBreakdown: { breakdownItem = item },
                                onBrainDump: { brainDumpItem = item },
                                onDecisionFatigue: { decisionFatigueItem = item },
                                onExecFunction: { execFunctionItem = item },
                                onDraftCommunication: item.itemType == .communication ? { draftItem = item } : nil
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
                    VStack(spacing: 0) {
                        quickCaptureBar
                        Color.clear.frame(height: ctaClearance)
                    }
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
                            tileSize: 44,
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
                            tileSize: 44,
                            style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
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
                AccountView(showsDismiss: true)
                    .environmentObject(themeManager)
                    .environment(AuthManager.shared)
            }
            .sheet(item: $selectedItem) { item in
                CaptureDetailView(item: item)
                    .environmentObject(themeManager)
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
                    get: { moveItem != nil && moveDestination != nil },
                    set: { presented in
                        if !presented {
                            moveItem = nil
                            moveDestination = nil
                        }
                    }
                )
            ) {
                if let item = moveItem, let destination = moveDestination {
                    MoveToCollectionSheet(
                        item: item,
                        isStructured: destination == .plan,
                        onComplete: {
                            moveItem = nil
                            moveDestination = nil
                            refreshItems()
                        }
                    )
                    .environmentObject(themeManager)
                }
            }
            .sheet(item: $breakdownItem) { item in
                BreakdownSheet(item: item)
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $brainDumpItem) { item in
                BrainDumpSheet(item: item)
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $decisionFatigueItem) { item in
                DecisionFatigueSheet(item: item)
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $execFunctionItem) { item in
                ExecFunctionSheet(item: item)
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $draftItem) { item in
                CommunicationDraftSheet(item: item)
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Delete this item? This cannot be undone.",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Item", role: .destructive) {
                    if let item = itemToDelete {
                        deleteItem(item)
                    }
                    itemToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
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

    // MARK: - Type Filter Bar

    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(ItemType.allCases.filter(\.isUserAssignable), id: \.rawValue) { type in
                    let isSelected = viewModel.typeFilter == type
                    Button {
                        setTypeFilter(isSelected ? nil : type)
                    } label: {
                        Label(type.displayName, systemImage: type.icon)
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(
                                isSelected
                                    ? Theme.Colors.accentButtonText(colorScheme, style: style)
                                    : Theme.Colors.textSecondary(colorScheme, style: style)
                            )
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(
                                        isSelected
                                            ? Theme.Colors.primary(colorScheme, style: style)
                                            : Theme.Colors.primary(colorScheme, style: style).opacity(0.08)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        Theme.Colors.primary(colorScheme, style: style).opacity(isSelected ? 0 : 0.25),
                                        lineWidth: 0.8
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(type.displayName) filter")
                    .accessibilityHint(isSelected ? "Active. Tap to show all types." : "Tap to filter by \(type.displayName).")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Quick Capture Bar

    /// Persistent inline text bar pinned above the floating tab bar for zero-step captures.
    private var quickCaptureBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("What's on your mind?", text: $quickCaptureText)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                .onSubmit { quickSave() }
                .submitLabel(.send)
                .onChange(of: quickCaptureText) { _, new in
                    if new.count > PendingCaptureStore.maxContentLength {
                        quickCaptureText = String(new.prefix(PendingCaptureStore.maxContentLength))
                    }
                }
                .accessibilityLabel("Quick capture")
                .accessibilityHint("Type a thought and hit return to save instantly.")
                .accessibilityValue(isQuickCaptureAtLimit ? "Character limit reached" : "")

            Button(action: quickSave) {
                AppIcon(name: isQuickCaptureEmpty ? "arrow.up.circle" : "arrow.up.circle.fill", size: 26)
                    .foregroundStyle(
                        isQuickCaptureEmpty
                            ? Theme.Colors.textSecondary(colorScheme, style: style).opacity(0.4)
                            : Theme.Colors.primary(colorScheme, style: style)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isQuickCaptureEmpty)
            .accessibilityLabel("Send")
            .accessibilityHint("Save this capture.")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Theme.Surface.card(colorScheme, style: style)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.3))
                        .frame(height: 0.5)
                }
        )
    }

    /// Saves the quick-bar text as a bare capture (type: nil, no tags, no attachment).
    private func quickSave() {
        let trimmed = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            _ = try itemRepository.create(
                type: nil,
                content: trimmed,
                attachmentData: nil,
                tags: [],
                isStarred: false
            )
            quickCaptureText = ""
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            refreshItems()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func setTypeFilter(_ type: ItemType?) {
        do {
            try viewModel.setTypeFilter(type, using: itemRepository)
        } catch {
            errorPresenter.present(error)
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

            // Celebrate successful completion
            UIImpactFeedbackGenerator(style: CelebrationStyle.itemCompleted.hapticStyle).impactOccurred()
            toastManager.show("Done!", type: .success)

            // Check if this completion finishes any collection
            checkCollectionCompletion(for: item)
        } catch {
            AppLogger.workflow.error(
                "CaptureView complete failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            errorPresenter.present(error)
        }
    }

    /// Checks if completing this item finishes all items in any of its collections.
    private func checkCollectionCompletion(for item: Item) {
        guard let collectionItems = item.collectionItems, !collectionItems.isEmpty else { return }

        for collectionItem in collectionItems {
            guard let collection = collectionItem.collection,
                  let allCollectionItems = collection.collectionItems,
                  !allCollectionItems.isEmpty else { continue }

            let allItems = allCollectionItems.compactMap(\.item)
            guard !allItems.isEmpty else { continue }

            let allComplete = allItems.allSatisfy { $0.completedAt != nil }
            if allComplete {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                toastManager.show("\"\(collection.name)\" complete!", type: .success)
                AppLogger.workflow.info("Collection completed - name: \(collection.name, privacy: .public)")
            }
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

#Preview {
    CaptureView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
