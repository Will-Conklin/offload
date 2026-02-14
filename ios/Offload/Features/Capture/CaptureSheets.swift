// Purpose: Sheet views for CaptureView.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI

// MARK: - Capture Detail View

struct CaptureDetailView: View {
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

struct MoveToPlanSheet: View {
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
    @State private var isLoading = true
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if !collections.isEmpty {
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
        isLoading = false
    }

    private func moveToSelectedPlan() {
        guard let collection = selectedCollection else { return }

        do {
            let position = collection.collectionItems?.count ?? 0
            try itemRepository.moveToCollectionAtomically(item, collection: collection, targetType: "task", position: position)

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

            try itemRepository.moveToCollectionAtomically(item, collection: collection, targetType: "task", position: 0)

            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Move to List Sheet

struct MoveToListSheet: View {
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
    @State private var isLoading = true
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if !collections.isEmpty {
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
        isLoading = false
    }

    private func moveToSelectedList() {
        guard let collection = selectedCollection else { return }

        do {
            try itemRepository.moveToCollectionAtomically(item, collection: collection, targetType: "task", position: nil)

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

            try itemRepository.moveToCollectionAtomically(item, collection: collection, targetType: "task", position: nil)

            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }
}
