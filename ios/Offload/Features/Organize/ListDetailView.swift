//
//  ListDetailView.swift
//  Offload
//
//  Created by Claude Code on 1/5/26.
//
//  Intent: Detail view for managing a list and its items.
//

import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var list: ListEntity

    @State private var showingEditList = false
    @State private var showingAddItem = false
    @State private var showingDeleteConfirmation = false
    @State private var newItemText = ""
    @State private var errorMessage: String?

    private var uncheckedItems: [ListItem] {
        list.items?.filter { !$0.isChecked }.sorted { $0.text < $1.text } ?? []
    }

    private var checkedItems: [ListItem] {
        list.items?.filter { $0.isChecked }.sorted { $0.text < $1.text } ?? []
    }

    var body: some View {
        List {
            // List Details Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(list.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Text(list.listKind.rawValue.capitalized)
                            .font(Theme.Typography.badge)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.accentPrimary(colorScheme).opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.sm)
                    }

                    if let itemCount = list.items?.count, itemCount > 0 {
                        let checkedCount = checkedItems.count
                        HStack {
                            Text("\(checkedCount)/\(itemCount) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(list.createdAt, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Quick Add Section
            Section {
                HStack {
                    TextField("Add item...", text: $newItemText)
                        .onSubmit {
                            addQuickItem()
                        }

                    if !newItemText.isEmpty {
                        Button("Add") {
                            addQuickItem()
                        }
                    }
                }
            }

            // Unchecked Items Section
            if !uncheckedItems.isEmpty {
                Section("Items") {
                    ForEach(uncheckedItems) { item in
                        ListItemRowView(item: item)
                    }
                    .onDelete(perform: deleteUncheckedItems)
                }
            }

            // Checked Items Section
            if !checkedItems.isEmpty {
                Section("Completed") {
                    ForEach(checkedItems) { item in
                        ListItemRowView(item: item)
                    }
                    .onDelete(perform: deleteCheckedItems)
                }
            }
        }
        .navigationTitle("List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditList = true
                    } label: {
                        Label("Edit List", systemImage: "pencil")
                    }

                    if let items = list.items, !items.isEmpty {
                        Button {
                            clearCompleted()
                        } label: {
                            Label("Clear Completed", systemImage: "trash")
                        }
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditList) {
            EditListSheet(list: list)
        }
        .alert("Delete List?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteList()
            }
        } message: {
            Text("This will delete the list and all its items. This cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private func addQuickItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = ListItem(text: trimmed, list: list)
        modelContext.insert(item)

        do {
            try modelContext.save()
            newItemText = ""
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to add item: \(error.localizedDescription)"
        }
    }

    private func deleteUncheckedItems(offsets: IndexSet) {
        // Capture items to delete before modifying
        let itemsToDelete = offsets.map { uncheckedItems[$0] }

        for item in itemsToDelete {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete items: \(error.localizedDescription)"
        }
    }

    private func deleteCheckedItems(offsets: IndexSet) {
        // Capture items to delete before modifying
        let itemsToDelete = offsets.map { checkedItems[$0] }

        for item in itemsToDelete {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete items: \(error.localizedDescription)"
        }
    }

    private func clearCompleted() {
        guard let items = list.items else { return }
        for item in items where item.isChecked {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to clear completed items: \(error.localizedDescription)"
        }
    }

    private func deleteList() {
        modelContext.delete(list)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete list: \(error.localizedDescription)"
        }
    }
}

private struct ListItemRowView: View {
    @Bindable var item: ListItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                item.isChecked.toggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(item.text)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? .secondary : .primary)
        }
    }
}

private struct EditListSheet: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var list: ListEntity

    @State private var title: String
    @State private var kind: ListKind

    init(list: ListEntity) {
        self.list = list
        _title = State(initialValue: list.title)
        _kind = State(initialValue: list.listKind)
    }

    var body: some View {
        FormSheet(
            title: "Edit List",
            saveButtonTitle: "Save",
            isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    throw ValidationError("List title is required.")
                }

                list.title = trimmedTitle
                list.listKind = kind

                try modelContext.save()
            }
        ) {
            Section("Details") {
                TextField("List title", text: $title)
                Picker("Type", selection: $kind) {
                    ForEach(ListKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}


#Preview {
    let list = ListEntity(title: "Sample List", kind: .shopping)

    NavigationStack {
        ListDetailView(list: list)
    }
    .modelContainer(PersistenceController.preview)
}
