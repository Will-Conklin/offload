//
//  OrganizeView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Manual organization hub for creating plans, categories, and tags.
//  Keeps quick-add flows lightweight to match capture-first philosophy.
//

import SwiftUI
import SwiftData

struct OrganizeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query(sort: \ListEntity.createdAt, order: .reverse) private var lists: [ListEntity]
    @Query(sort: \CommunicationItem.createdAt, order: .reverse) private var communications: [CommunicationItem]

    @State private var activeSheet: OrganizeSheet?

    var body: some View {
        NavigationStack {
            List {
                Section("Plans") {
                    if plans.isEmpty {
                        Text("No plans yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(plans) { plan in
                            NavigationLink(destination: PlanDetailView(plan: plan)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.title)
                                        .font(.headline)

                                    if let detail = plan.detail, !detail.isEmpty {
                                        Text(detail)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }

                                    HStack {
                                        Text(plan.createdAt, format: .dateTime.month().day().year())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if let taskCount = plan.tasks?.count, taskCount > 0 {
                                            Spacer()
                                            Text("\(taskCount) tasks")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deletePlans)
                    }

                    Button {
                        activeSheet = .plan
                    } label: {
                        Label("New Plan", systemImage: "plus.circle.fill")
                    }
                }

                Section("Categories") {
                    if categories.isEmpty {
                        Text("No categories yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                if let icon = category.icon, !icon.isEmpty {
                                    Text(icon)
                                        .font(.title3)
                                }
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }

                    Button {
                        activeSheet = .category
                    } label: {
                        Label("New Category", systemImage: "plus.circle.fill")
                    }
                }

                Section("Tags") {
                    if tags.isEmpty {
                        Text("No tags yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tags) { tag in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tag.name)
                                if let color = tag.color, !color.isEmpty {
                                    Text(color)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteTags)
                    }

                    Button {
                        activeSheet = .tag
                    } label: {
                        Label("New Tag", systemImage: "plus.circle.fill")
                    }
                }

                Section("Lists") {
                    if lists.isEmpty {
                        Text("No lists yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(lists) { list in
                            NavigationLink(destination: ListDetailView(list: list)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(list.title)
                                            .font(.headline)
                                        Spacer()
                                        Text(list.listKind.rawValue.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                    }

                                    if let itemCount = list.items?.count, itemCount > 0 {
                                        let checkedCount = list.items?.filter { $0.isChecked }.count ?? 0
                                        Text("\(checkedCount)/\(itemCount) items")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteLists)
                    }

                    Button {
                        activeSheet = .list
                    } label: {
                        Label("New List", systemImage: "plus.circle.fill")
                    }
                }

                Section("Communications") {
                    if communications.isEmpty {
                        Text("No communications yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(communications) { comm in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: iconForChannel(comm.communicationChannel))
                                        .foregroundStyle(.blue)
                                    Text(comm.recipient)
                                        .font(.headline)
                                    Spacer()
                                    if comm.communicationStatus == .sent {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }

                                Text(comm.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)

                                Text(comm.createdAt, format: .dateTime.month().day().year())
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .onDelete(perform: deleteCommunications)
                    }

                    Button {
                        activeSheet = .communication
                    } label: {
                        Label("New Communication", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Organize")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New Plan") {
                            activeSheet = .plan
                        }
                        Button("New List") {
                            activeSheet = .list
                        }
                        Button("New Communication") {
                            activeSheet = .communication
                        }
                        Divider()
                        Button("New Category") {
                            activeSheet = .category
                        }
                        Button("New Tag") {
                            activeSheet = .tag
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .plan:
                    PlanFormSheet { title, detail in
                        try createPlan(title: title, detail: detail)
                    }
                case .category:
                    CategoryFormSheet { name, icon in
                        try createCategory(name: name, icon: icon)
                    }
                case .tag:
                    TagFormSheet { name, color in
                        try createTag(name: name, color: color)
                    }
                case .list:
                    ListFormSheet { title, kind in
                        try createList(title: title, kind: kind)
                    }
                case .communication:
                    CommunicationFormSheet { channel, recipient, content in
                        try createCommunication(channel: channel, recipient: recipient, content: content)
                    }
                }
            }
        }
    }

    private func createPlan(title: String, detail: String?) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ValidationError("Plan title is required.")
        }

        let normalizedDetail = detail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = Plan(
            title: trimmedTitle,
            detail: (normalizedDetail?.isEmpty ?? true) ? nil : normalizedDetail
        )

        modelContext.insert(plan)
        try modelContext.save()
    }

    private func createCategory(name: String, icon: String?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("Category name is required.")
        }

        let normalizedIcon = icon?.trimmingCharacters(in: .whitespacesAndNewlines)
        let repository = CategoryRepository(modelContext: modelContext)
        _ = try repository.findOrCreate(
            name: trimmedName,
            icon: (normalizedIcon?.isEmpty ?? true) ? nil : normalizedIcon
        )
    }

    private func createTag(name: String, color: String?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("Tag name is required.")
        }

        let normalizedColor = color?.trimmingCharacters(in: .whitespacesAndNewlines)
        let repository = TagRepository(modelContext: modelContext)
        _ = try repository.findOrCreate(
            name: trimmedName,
            color: (normalizedColor?.isEmpty ?? true) ? nil : normalizedColor
        )
    }

    private func deletePlans(offsets: IndexSet) {
        for index in offsets {
            let plan = plans[index]
            modelContext.delete(plan)
        }
        try? modelContext.save()
    }

    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            modelContext.delete(category)
        }
        try? modelContext.save()
    }

    private func deleteTags(offsets: IndexSet) {
        for index in offsets {
            let tag = tags[index]
            modelContext.delete(tag)
        }
        try? modelContext.save()
    }

    private func createList(title: String, kind: ListKind) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ValidationError("List title is required.")
        }

        let list = ListEntity(title: trimmedTitle, kind: kind)
        modelContext.insert(list)
        try modelContext.save()
    }

    private func deleteLists(offsets: IndexSet) {
        for index in offsets {
            let list = lists[index]
            modelContext.delete(list)
        }
        try? modelContext.save()
    }

    private func createCommunication(channel: CommunicationChannel, recipient: String, content: String) throws {
        let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedRecipient.isEmpty else {
            throw ValidationError("Recipient is required.")
        }
        guard !trimmedContent.isEmpty else {
            throw ValidationError("Content is required.")
        }

        let comm = CommunicationItem(
            channel: channel,
            recipient: trimmedRecipient,
            content: trimmedContent
        )
        modelContext.insert(comm)
        try modelContext.save()
    }

    private func deleteCommunications(offsets: IndexSet) {
        for index in offsets {
            let comm = communications[index]
            modelContext.delete(comm)
        }
        try? modelContext.save()
    }

    private func iconForChannel(_ channel: CommunicationChannel) -> String {
        switch channel {
        case .call:
            return "phone.fill"
        case .email:
            return "envelope.fill"
        case .text:
            return "message.fill"
        case .other:
            return "ellipsis.message.fill"
        }
    }
}

private enum OrganizeSheet: Identifiable {
    case plan
    case category
    case tag
    case list
    case communication

    var id: String {
        switch self {
        case .plan:
            return "plan"
        case .category:
            return "category"
        case .tag:
            return "tag"
        case .list:
            return "list"
        case .communication:
            return "communication"
        }
    }
}

private struct PlanFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String?) throws -> Void

    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Plan title", text: $title)
                    TextField("Description (optional)", text: $detail, axis: .vertical)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

            try onSave(
                trimmedTitle,
                trimmedDetail.isEmpty ? nil : trimmedDetail
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String?) throws -> Void

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category name", text: $name)
                    TextField("Emoji (optional)", text: $icon)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)

            try onSave(
                trimmedName,
                trimmedIcon.isEmpty ? nil : trimmedIcon
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct TagFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String?) throws -> Void

    @State private var name: String = ""
    @State private var color: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Tag name", text: $name)
                    TextField("Color (optional)", text: $color)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedColor = color.trimmingCharacters(in: .whitespacesAndNewlines)

            try onSave(
                trimmedName,
                trimmedColor.isEmpty ? nil : trimmedColor
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ListFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, ListKind) throws -> Void

    @State private var title: String = ""
    @State private var kind: ListKind = .reference
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("List title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(ListKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            try onSave(trimmedTitle, kind)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CommunicationFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (CommunicationChannel, String, String) throws -> Void

    @State private var channel: CommunicationChannel = .text
    @State private var recipient: String = ""
    @State private var content: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Channel", selection: $channel) {
                        ForEach(CommunicationChannel.allCases, id: \.self) { channel in
                            Label(channel.rawValue.capitalized, systemImage: iconForChannel(channel))
                                .tag(channel)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Recipient", text: $recipient)
                    TextField("Message", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Communication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(
                        recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }

    private func handleSave() {
        do {
            let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            try onSave(channel, trimmedRecipient, trimmedContent)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func iconForChannel(_ channel: CommunicationChannel) -> String {
        switch channel {
        case .call:
            return "phone.fill"
        case .email:
            return "envelope.fill"
        case .text:
            return "message.fill"
        case .other:
            return "ellipsis.message.fill"
        }
    }
}

private struct ValidationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

#Preview {
    OrganizeView()
        .modelContainer(PersistenceController.preview)
}
