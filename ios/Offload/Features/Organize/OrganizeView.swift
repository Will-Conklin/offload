//
//  OrganizeView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Manual organization hub for creating plans, categories, and tags.
//  Keeps quick-add flows lightweight to match capture-first philosophy.
//

import SwiftData
import SwiftUI

struct OrganizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]
    @Query(sort: \ListEntity.createdAt, order: .reverse) private var lists: [ListEntity]
    @Query(sort: \CommunicationItem.createdAt, order: .reverse) private var communications: [CommunicationItem]

    @State private var activeSheet: OrganizeSheet?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Plans") {
                    if plans.isEmpty {
                        Text("No plans yet")
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    } else {
                        ForEach(plans) { plan in
                            NavigationLink(destination: PlanDetailView(plan: plan)) {
                                CardView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.title)
                                            .font(Theme.Typography.cardTitle)

                                        if let detail = plan.detail, !detail.isEmpty {
                                            Text(detail)
                                                .font(Theme.Typography.cardBody)
                                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                                                .lineLimit(2)
                                        }

                                        HStack {
                                            Text(plan.createdAt, format: .dateTime.month().day().year())
                                                .font(Theme.Typography.metadata)
                                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

                                            if let taskCount = plan.tasks?.count, taskCount > 0 {
                                                Spacer()
                                                Text("\(taskCount) tasks")
                                                    .font(Theme.Typography.metadata)
                                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .accessibilityHint("Opens plan details")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deletePlans)
                    }

                    Button {
                        activeSheet = .plan
                    } label: {
                        Label("New Plan", systemImage: "plus.circle.fill")
                    }
                }

                Section("Lists") {
                    if lists.isEmpty {
                        Text("No lists yet")
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    } else {
                        ForEach(lists) { list in
                            NavigationLink(destination: ListDetailView(list: list)) {
                                CardView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(list.title)
                                                .font(Theme.Typography.cardTitle)
                                            Spacer()
                                            Badge(text: list.listKind.rawValue.capitalized, style: .accent)
                                        }

                                        if let itemCount = list.items?.count, itemCount > 0 {
                                            let checkedCount = list.items?.filter(\.isChecked).count ?? 0
                                            Text("\(checkedCount)/\(itemCount) items")
                                                .font(Theme.Typography.metadata)
                                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .accessibilityHint("Opens list details")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    } else {
                        ForEach(communications) { comm in
                            ExpandableCard(
                                bodyText: comm.content,
                                accessibilityLabel: "Communication from \(comm.recipient)"
                            ) {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    HStack {
                                        Image(systemName: iconForChannel(comm.communicationChannel))
                                            .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                                        Text(comm.recipient)
                                            .font(Theme.Typography.cardTitle)
                                        Spacer()
                                        if comm.communicationStatus == .sent {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Theme.Colors.success(colorScheme, style: themeManager.currentStyle))
                                        }
                                    }

                                    Text(comm.createdAt, format: .dateTime.month().day().year())
                                        .font(Theme.Typography.metadata)
                                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityLabel("Add item")
                    .accessibilityHint("Opens options to create a plan, list, or communication")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .plan:
                    PlanFormSheet { title, detail in
                        try createPlan(title: title, detail: detail)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                case .list:
                    ListFormSheet { title, kind in
                        try createList(title: title, kind: kind)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                case .communication:
                    CommunicationFormSheet { channel, recipient, content in
                        try createCommunication(channel: channel, recipient: recipient, content: content)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") {
                    errorMessage = nil
                }
                .accessibilityLabel("Dismiss error")
            } message: { message in
                Text(message)
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

    private func deletePlans(offsets: IndexSet) {
        for index in offsets {
            let plan = plans[index]
            modelContext.delete(plan)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete plans: \(error.localizedDescription)"
        }
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

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete lists: \(error.localizedDescription)"
        }
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

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete communications: \(error.localizedDescription)"
        }
    }

    private func iconForChannel(_ channel: CommunicationChannel) -> String {
        switch channel {
        case .call:
            "phone.fill"
        case .email:
            "envelope.fill"
        case .text:
            "message.fill"
        case .other:
            "ellipsis.message.fill"
        }
    }
}

private enum OrganizeSheet: Identifiable {
    case plan
    case list
    case communication

    var id: String {
        switch self {
        case .plan:
            "plan"
        case .list:
            "list"
        case .communication:
            "communication"
        }
    }
}

private struct PlanFormSheet: View {
    let onSave: (String, String?) async throws -> Void

    @State private var title: String = ""
    @State private var detail: String = ""

    var body: some View {
        FormSheet(
            title: "New Plan",
            saveButtonTitle: "Save",
            isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    throw ValidationError("Plan title is required.")
                }

                try await onSave(
                    trimmedTitle,
                    trimmedDetail.isEmpty ? nil : trimmedDetail
                )
            }
        ) {
            Section("Details") {
                TextField("Plan title", text: $title)
                    .accessibilityLabel("Plan title")
                TextField("Description (optional)", text: $detail, axis: .vertical)
                    .accessibilityLabel("Plan description")
            }
        }
    }
}

private struct CategoryFormSheet: View {
    let onSave: (String, String?) async throws -> Void

    @State private var name: String = ""
    @State private var icon: String = ""

    var body: some View {
        FormSheet(
            title: "New Category",
            saveButtonTitle: "Save",
            isSaveDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedName.isEmpty else {
                    throw ValidationError("Category name is required.")
                }

                try await onSave(
                    trimmedName,
                    trimmedIcon.isEmpty ? nil : trimmedIcon
                )
            }
        ) {
            Section("Details") {
                TextField("Category name", text: $name)
                    .accessibilityLabel("Category name")
                TextField("Emoji (optional)", text: $icon)
                    .accessibilityLabel("Category emoji")
            }
        }
    }
}

private struct TagFormSheet: View {
    let onSave: (String, String?) async throws -> Void

    @State private var name: String = ""
    @State private var color: String = ""

    var body: some View {
        FormSheet(
            title: "New Tag",
            saveButtonTitle: "Save",
            isSaveDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedColor = color.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedName.isEmpty else {
                    throw ValidationError("Tag name is required.")
                }

                try await onSave(
                    trimmedName,
                    trimmedColor.isEmpty ? nil : trimmedColor
                )
            }
        ) {
            Section("Details") {
                TextField("Tag name", text: $name)
                    .accessibilityLabel("Tag name")
                TextField("Color (optional)", text: $color)
                    .accessibilityLabel("Tag color")
            }
        }
    }
}

private struct ListFormSheet: View {
    let onSave: (String, ListKind) async throws -> Void

    @State private var title: String = ""
    @State private var kind: ListKind = .reference

    var body: some View {
        FormSheet(
            title: "New List",
            saveButtonTitle: "Save",
            isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    throw ValidationError("List title is required.")
                }

                try await onSave(trimmedTitle, kind)
            }
        ) {
            Section("Details") {
                TextField("List title", text: $title)
                    .accessibilityLabel("List title")
                Picker("Type", selection: $kind) {
                    ForEach(ListKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Select the list type")
            }
        }
    }
}

private struct CommunicationFormSheet: View {
    let onSave: (CommunicationChannel, String, String) async throws -> Void

    @State private var channel: CommunicationChannel = .text
    @State private var recipient: String = ""
    @State private var content: String = ""

    var body: some View {
        FormSheet(
            title: "New Communication",
            saveButtonTitle: "Save",
            isSaveDisabled: recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedRecipient.isEmpty else {
                    throw ValidationError("Recipient is required.")
                }
                guard !trimmedContent.isEmpty else {
                    throw ValidationError("Content is required.")
                }

                try await onSave(channel, trimmedRecipient, trimmedContent)
            }
        ) {
            Section("Type") {
                Picker("Channel", selection: $channel) {
                    ForEach(CommunicationChannel.allCases, id: \.self) { channel in
                        Label(channel.rawValue.capitalized, systemImage: iconForChannel(channel))
                            .tag(channel)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Select how you plan to communicate")
            }

            Section("Details") {
                TextField("Recipient", text: $recipient)
                    .accessibilityLabel("Recipient")
                TextField("Message", text: $content, axis: .vertical)
                    .lineLimit(3 ... 6)
                    .accessibilityLabel("Message")
            }
        }
    }

    private func iconForChannel(_ channel: CommunicationChannel) -> String {
        switch channel {
        case .call:
            "phone.fill"
        case .email:
            "envelope.fill"
        case .text:
            "message.fill"
        case .other:
            "ellipsis.message.fill"
        }
    }
}

#Preview {
    OrganizeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
