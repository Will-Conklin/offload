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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.title)
                                    .font(.headline)

                                if let detail = plan.detail, !detail.isEmpty {
                                    Text(detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Text(plan.createdAt, format: .dateTime.month().day().year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                    }

                    Button {
                        activeSheet = .tag
                    } label: {
                        Label("New Tag", systemImage: "plus.circle.fill")
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
}

private enum OrganizeSheet: Identifiable {
    case plan
    case category
    case tag

    var id: String {
        switch self {
        case .plan:
            return "plan"
        case .category:
            return "category"
        case .tag:
            return "tag"
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
