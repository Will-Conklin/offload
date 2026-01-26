// Purpose: Capture feature views and flows.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve low-friction capture UX and Item.type == nil semantics.

//  Flat design capture list with inline tagging and swipe actions

import SwiftUI
import SwiftData
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
    @State private var showingAddItem = false
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
            ZStack(alignment: .bottomTrailing) {
                // Background
                Theme.Colors.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        if viewModel.items.isEmpty && viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, Theme.Spacing.sm)
                        }

                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            ItemCard(
                                index: index,
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

                        if viewModel.isLoading && !viewModel.items.isEmpty {
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

                FloatingActionButton(title: "Add Item", iconName: Icons.addCircleFilled) {
                    showingAddItem = true
                }
                .accessibilityLabel("Add Item")
                .padding(.trailing, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAddItem, onDismiss: refreshItems) {
                CaptureComposeView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedItem) { item in
                CaptureDetailView(item: item)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $tagPickerItem) { item in
                ItemTagPickerSheet(item: item)
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
        do {
            try itemRepository.delete(item)
            viewModel.remove(item)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func completeItem(_ item: Item) {
        do {
            try itemRepository.complete(item)
            viewModel.remove(item)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func toggleStar(_ item: Item) {
        do {
            try itemRepository.toggleStar(item)
        } catch {
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
    let index: Int
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

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(item.content)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))

                    if let attachmentData = item.attachmentData,
                       let uiImage = UIImage(data: attachmentData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                    }

                    Text(item.createdAt, format: .relative(presentation: .named))
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                }

                ItemActionRow(
                    tags: item.tags,
                    isStarred: item.isStarred,
                    onAddTag: onAddTag,
                    onToggleStar: onToggleStar
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .overlay(
            // Swipe indicators
            HStack {
                if offset > 0 {
                    AppIcon(name: Icons.checkCircleFilled, size: 18)
                        .foregroundStyle(Theme.Colors.success(colorScheme, style: style))
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

#Preview {
    CaptureView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
