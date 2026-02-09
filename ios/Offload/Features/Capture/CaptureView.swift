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

#Preview {
    CaptureView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
