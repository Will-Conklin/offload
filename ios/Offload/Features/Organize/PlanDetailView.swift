//
//  PlanDetailView.swift
//  Offload
//
//  Created by Claude Code on 1/5/26.
//
//  Intent: Detail view for managing a plan and its tasks.
//

import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var plan: Plan

    @State private var showingEditPlan = false
    @State private var showingAddTask = false
    @State private var showingDeleteConfirmation = false
    @State private var taskToEdit: Task?
    @State private var errorMessage: String?

    private var activeTasks: [Task] {
        plan.tasks?.filter { !$0.isDone }.sorted { $0.importance > $1.importance } ?? []
    }

    private var completedTasks: [Task] {
        plan.tasks?.filter { $0.isDone }.sorted { $0.createdAt > $1.createdAt } ?? []
    }

    var body: some View {
        List {
            // Plan Details Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let detail = plan.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(plan.createdAt, format: .dateTime.month().day().year())
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        if let taskCount = plan.tasks?.count, taskCount > 0 {
                            let completed = completedTasks.count
                            Text("\(completed)/\(taskCount) tasks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Active Tasks Section
            if !activeTasks.isEmpty {
                Section("Active Tasks") {
                    ForEach(activeTasks) { task in
                        TaskRowView(task: task, plan: plan)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                taskToEdit = task
                            }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }

            // Completed Tasks Section
            if !completedTasks.isEmpty {
                Section("Completed") {
                    ForEach(completedTasks) { task in
                        TaskRowView(task: task, plan: plan)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                taskToEdit = task
                            }
                    }
                    .onDelete(perform: deleteCompletedTasks)
                }
            }

            // Add Task Button
            Section {
                Button {
                    showingAddTask = true
                } label: {
                    Label("Add Task", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditPlan = true
                    } label: {
                        Label("Edit Plan", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Plan", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPlanSheet(plan: plan)
        }
        .sheet(isPresented: $showingAddTask) {
            TaskFormSheet(plan: plan) { title, detail, importance, dueDate in
                try createTask(title: title, detail: detail, importance: importance, dueDate: dueDate)
            }
        }
        .sheet(item: $taskToEdit) { task in
            TaskFormSheet(plan: plan, existingTask: task) { title, detail, importance, dueDate in
                try updateTask(task, title: title, detail: detail, importance: importance, dueDate: dueDate)
            }
        }
        .alert("Delete Plan?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePlan()
            }
        } message: {
            Text("This will delete the plan and all its tasks. This cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private func createTask(title: String, detail: String?, importance: Int, dueDate: Date?) throws {
        let task = Task(
            title: title,
            detail: detail,
            importance: importance,
            dueDate: dueDate,
            plan: plan
        )

        modelContext.insert(task)
        try modelContext.save()
    }

    private func updateTask(_ task: Task, title: String, detail: String?, importance: Int, dueDate: Date?) throws {
        task.title = title
        task.detail = detail
        task.importance = importance
        task.dueDate = dueDate

        try modelContext.save()
    }

    private func deleteTasks(offsets: IndexSet) {
        // Capture tasks to delete before modifying
        let tasksToDelete = offsets.map { activeTasks[$0] }

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete tasks: \(error.localizedDescription)"
        }
    }

    private func deleteCompletedTasks(offsets: IndexSet) {
        // Capture tasks to delete before modifying
        let tasksToDelete = offsets.map { completedTasks[$0] }

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete tasks: \(error.localizedDescription)"
        }
    }

    private func deletePlan() {
        modelContext.delete(plan)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = "Failed to delete plan: \(error.localizedDescription)"
        }
    }
}

private struct TaskRowView: View {
    @Bindable var task: Task
    let plan: Plan

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                task.isDone.toggle()
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)

                if let detail = task.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if task.importance != 3 {
                        importanceView(task.importance)
                    }

                    if let dueDate = task.dueDate {
                        Text(dueDate, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(dueDate < Date() ? .red : .secondary)
                    }
                }
            }
        }
    }

    private func importanceView(_ importance: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<importance, id: \.self) { _ in
                Image(systemName: "exclamationmark")
                    .font(.caption2)
            }
        }
        .foregroundStyle(importance >= 4 ? .red : .orange)
    }
}

private struct EditPlanSheet: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var plan: Plan

    @State private var title: String
    @State private var detail: String

    init(plan: Plan) {
        self.plan = plan
        _title = State(initialValue: plan.title)
        _detail = State(initialValue: plan.detail ?? "")
    }

    var body: some View {
        FormSheet(
            title: "Edit Plan",
            saveButtonTitle: "Save",
            isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    throw ValidationError("Plan title is required.")
                }

                plan.title = trimmedTitle
                plan.detail = trimmedDetail.isEmpty ? nil : trimmedDetail

                try modelContext.save()
            }
        ) {
            Section("Details") {
                TextField("Plan title", text: $title)
                TextField("Description (optional)", text: $detail, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }
}

private struct TaskFormSheet: View {
    let plan: Plan
    let existingTask: Task?
    let onSave: (String, String?, Int, Date?) async throws -> Void

    @State private var title: String
    @State private var detail: String
    @State private var importance: Int
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(plan: Plan, existingTask: Task? = nil, onSave: @escaping (String, String?, Int, Date?) async throws -> Void) {
        self.plan = plan
        self.existingTask = existingTask
        self.onSave = onSave

        _title = State(initialValue: existingTask?.title ?? "")
        _detail = State(initialValue: existingTask?.detail ?? "")
        _importance = State(initialValue: existingTask?.importance ?? 3)
        _hasDueDate = State(initialValue: existingTask?.dueDate != nil)
        _dueDate = State(initialValue: existingTask?.dueDate ?? Date())
    }

    var body: some View {
        FormSheet(
            title: existingTask == nil ? "New Task" : "Edit Task",
            saveButtonTitle: "Save",
            isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onSave: {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    throw ValidationError("Task title is required.")
                }

                try await onSave(
                    trimmedTitle,
                    trimmedDetail.isEmpty ? nil : trimmedDetail,
                    importance,
                    hasDueDate ? dueDate : nil
                )
            }
        ) {
            Section("Details") {
                TextField("Task title", text: $title)
                TextField("Notes (optional)", text: $detail, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Importance") {
                Picker("Importance", selection: $importance) {
                    Text("Very Low (1)").tag(1)
                    Text("Low (2)").tag(2)
                    Text("Medium (3)").tag(3)
                    Text("High (4)").tag(4)
                    Text("Very High (5)").tag(5)
                }
                .pickerStyle(.menu)
            }

            Section {
                Toggle("Set Due Date", isOn: $hasDueDate)

                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
        }
    }
}


#Preview {
    let plan = Plan(title: "Sample Plan", detail: "A plan for testing")

    NavigationStack {
        PlanDetailView(plan: plan)
    }
    .modelContainer(PersistenceController.preview)
    .environmentObject(ThemeManager.shared)
}
