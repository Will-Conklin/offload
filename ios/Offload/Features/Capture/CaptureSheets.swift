// Purpose: Sheet views for CaptureView.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

// MARK: - Capture Detail View

struct CaptureDetailView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var errorPresenter = ErrorPresenter()
    @State private var content: String

    private var style: ThemeStyle { themeManager.currentStyle }

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
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
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

// MARK: - Move to Collection Sheet (unified Plan/List)

/// Unified sheet for moving an item to a plan or list collection.
struct MoveToCollectionSheet: View {
    let item: Item
    let isStructured: Bool
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newCollectionName = ""
    @State private var isLoading = true
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }
    private var collectionLabel: String { isStructured ? "Plan" : "List" }

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
                    Section("Select \(collectionLabel)") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelected()
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
                            Text("Create New \(collectionLabel)")
                        } icon: {
                            AppIcon(name: Icons.addCircleFilled, size: 16)
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to \(collectionLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New \(collectionLabel)", isPresented: $createNew) {
                TextField("\(collectionLabel) name", text: $newCollectionName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewAndMove()
                }
            } message: {
                Text("Enter a name for the new \(collectionLabel.lowercased())")
            }
            .onAppear {
                loadCollections()
            }
        }
        .errorToasts(errorPresenter)
    }

    private func loadCollections() {
        do {
            collections = isStructured
                ? try collectionRepository.fetchStructured()
                : try collectionRepository.fetchUnstructured()
        } catch {
            errorPresenter.present(error)
            collections = []
        }
        isLoading = false
    }

    private func moveToSelected() {
        guard let collection = selectedCollection else { return }

        do {
            let position = isStructured
                ? collectionRepository.nextPosition(in: collection, parentId: nil)
                : nil
            try itemRepository.moveToCollectionAtomically(
                item, collection: collection, targetType: "task", position: position
            )
            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func createNewAndMove() {
        let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let collection = try collectionRepository.create(name: trimmed, isStructured: isStructured)
            let position = isStructured ? 0 : nil
            try itemRepository.moveToCollectionAtomically(
                item, collection: collection, targetType: "task", position: position
            )
            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }
}
