//
//  ListDetailView.swift
//  Offload
//
//  Flat design list detail with simple checkboxes
//

import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Bindable var list: ListEntity

    @State private var showingEdit = false
    @State private var showingDelete = false
    @State private var newItemText = ""
    @State private var itemConversion: ItemConversion?

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header card
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text(list.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                        Spacer()

                        Text(list.listKind.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                            .clipShape(Capsule())
                    }

                    if let count = list.items?.count, count > 0 {
                        let checked = list.items?.filter { $0.isChecked }.count ?? 0
                        HStack {
                            Text("\(checked)/\(count) items")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                            Spacer()

                            Text(list.createdAt, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.card(colorScheme, style: style))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

                // Quick add
                HStack(spacing: Theme.Spacing.sm) {
                    TextField("Add item...", text: $newItemText)
                        .font(.body)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface(colorScheme, style: style))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        .onSubmit { addItem() }

                    if !newItemText.isEmpty {
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                        }
                    }
                }

                // Items
                if let items = list.items, !items.isEmpty {
                    let unchecked = items.filter { !$0.isChecked }.sorted { $0.text < $1.text }
                    let checked = items.filter { $0.isChecked }.sorted { $0.text < $1.text }

                    if !unchecked.isEmpty {
                        Text("Items")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                            .padding(.top, Theme.Spacing.sm)

                        ForEach(unchecked) { item in
                            ItemRow(item: item, colorScheme: colorScheme, style: style)
                                .contextMenu {
                                    Button {
                                        itemConversion = .toTask(item)
                                    } label: {
                                        Label("Convert to Task", systemImage: Icons.plans)
                                    }

                                    Button {
                                        itemConversion = .toComm(item)
                                    } label: {
                                        Label("Convert to Communication", systemImage: Icons.communications)
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        modelContext.delete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }

                    if !checked.isEmpty {
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                            .padding(.top, Theme.Spacing.sm)

                        ForEach(checked) { item in
                            ItemRow(item: item, colorScheme: colorScheme, style: style)
                                .contextMenu {
                                    Button {
                                        itemConversion = .toTask(item)
                                    } label: {
                                        Label("Convert to Task", systemImage: Icons.plans)
                                    }

                                    Button {
                                        itemConversion = .toComm(item)
                                    } label: {
                                        Label("Convert to Communication", systemImage: Icons.communications)
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        modelContext.delete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 100)
        }
        .background(Theme.Colors.background(colorScheme, style: style))
        .navigationTitle("List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    if let items = list.items, items.filter({ $0.isChecked }).count > 0 {
                        Button { clearCompleted() } label: {
                            Label("Clear Completed", systemImage: "trash")
                        }
                    }
                    Button(role: .destructive) { showingDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditListSheet(list: list)
        }
        .sheet(item: $itemConversion) { conversion in
            switch conversion {
            case .toTask(let item):
                ItemToTaskSheet(item: item, modelContext: modelContext) {
                    itemConversion = nil
                }
            case .toComm(let item):
                ItemToCommSheet(item: item, modelContext: modelContext) {
                    itemConversion = nil
                }
            }
        }
        .alert("Delete List?", isPresented: $showingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(list)
                dismiss()
            }
        } message: {
            Text("This will delete the list and all items.")
        }
    }

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = ListItem(text: trimmed, list: list)
        modelContext.insert(item)
        newItemText = ""
    }

    private func clearCompleted() {
        guard let items = list.items else { return }
        for item in items where item.isChecked {
            modelContext.delete(item)
        }
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    @Bindable var item: ListItem
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            Button { item.isChecked.toggle() } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? Theme.Colors.success(colorScheme, style: style) : Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .buttonStyle(.plain)

            Text(item.text)
                .font(.body)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? Theme.Colors.textSecondary(colorScheme, style: style) : Theme.Colors.textPrimary(colorScheme, style: style))

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface(colorScheme, style: style))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.border(colorScheme, style: style), lineWidth: 1)
        )
    }
}

// MARK: - Edit List Sheet

private struct EditListSheet: View {
    @Bindable var list: ListEntity
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var kind: ListKind

    init(list: ListEntity) {
        self.list = list
        _title = State(initialValue: list.title)
        _kind = State(initialValue: list.listKind)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Type", selection: $kind) {
                    ForEach(ListKind.allCases, id: \.self) { k in
                        Text(k.rawValue.capitalized).tag(k)
                    }
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.title = title
                        list.listKind = kind
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Item Conversion

enum ItemConversion: Identifiable {
    case toTask(ListItem)
    case toComm(ListItem)

    var id: String {
        switch self {
        case .toTask(let item): return "task-\(item.id)"
        case .toComm(let item): return "comm-\(item.id)"
        }
    }
}

// MARK: - Item to Task Sheet

private struct ItemToTaskSheet: View {
    let item: ListItem
    let modelContext: ModelContext
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]
    @State private var selectedPlan: Plan?
    @State private var createNew = false
    @State private var newPlanTitle = ""
    @State private var newPlanDetail = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !plans.isEmpty {
                    Section("Select Plan") {
                        ForEach(plans) { plan in
                            Button {
                                selectedPlan = plan
                                convertToSelectedPlan()
                            } label: {
                                HStack {
                                    Text(plan.title)
                                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                    Spacer()
                                    if let count = plan.tasks?.count {
                                        Text("\(count) tasks")
                                            .font(.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label("Create New Plan", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Convert to Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $createNew) {
                NavigationStack {
                    Form {
                        TextField("Plan title", text: $newPlanTitle)
                        TextField("Description (optional)", text: $newPlanDetail, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .navigationTitle("New Plan")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { createNew = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                createNewPlanAndConvert()
                            }
                            .disabled(newPlanTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func convertToSelectedPlan() {
        guard let plan = selectedPlan else { return }
        let task = Task(
            title: item.text,
            detail: nil,
            importance: 3,
            dueDate: nil,
            plan: plan
        )
        modelContext.insert(task)
        modelContext.delete(item)
        dismiss()
        onComplete()
    }

    private func createNewPlanAndConvert() {
        let trimmed = newPlanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let plan = Plan(
            title: trimmed,
            detail: newPlanDetail.isEmpty ? nil : newPlanDetail
        )
        modelContext.insert(plan)

        let task = Task(
            title: item.text,
            detail: nil,
            importance: 3,
            dueDate: nil,
            plan: plan
        )
        modelContext.insert(task)
        modelContext.delete(item)
        createNew = false
        dismiss()
        onComplete()
    }
}

// MARK: - Item to Comm Sheet

private struct ItemToCommSheet: View {
    let item: ListItem
    let modelContext: ModelContext
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var channel: CommunicationChannel = .text
    @State private var recipient = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            Form {
                Section("Communication Details") {
                    Picker("Type", selection: $channel) {
                        ForEach(CommunicationChannel.allCases, id: \.self) { c in
                            Text(c.rawValue.capitalized).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Recipient", text: $recipient)
                }

                Section("Message") {
                    Text(item.text)
                        .font(.body)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                }
            }
            .navigationTitle("Convert to Comm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createComm()
                    }
                    .disabled(recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createComm() {
        let trimmed = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let comm = CommunicationItem(
            channel: channel,
            recipient: trimmed,
            content: item.text
        )
        modelContext.insert(comm)
        modelContext.delete(item)
        dismiss()
        onComplete()
    }
}

#Preview {
    let list = ListEntity(title: "Sample List", kind: .shopping)

    NavigationStack {
        ListDetailView(list: list)
    }
    .modelContainer(PersistenceController.preview)
    .environmentObject(ThemeManager.shared)
}
