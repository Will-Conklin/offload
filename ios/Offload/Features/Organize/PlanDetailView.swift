//
//  PlanDetailView.swift
//  Offload
//
//  Flat design plan detail with nested tasks and drag to reorder
//

import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query private var plans: [Plan]
    let planID: UUID

    @State private var showingEdit = false
    @State private var showingAddTask = false
    @State private var showingDelete = false
    @State private var taskToEdit: Task?

    init(planID: UUID) {
        self.planID = planID
        _plans = Query(filter: #Predicate<Plan> { $0.id == planID })
    }

    private var plan: Plan? { plans.first }
    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        if let plan {
            planContent(plan)
        } else {
            missingView
        }
    }

    private func planContent(_ plan: Plan) -> some View {
        let active = plan.tasks?.filter { !$0.isDone }.sorted { $0.importance > $1.importance } ?? []
        let done = plan.tasks?.filter { $0.isDone } ?? []

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(plan.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                    if let detail = plan.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.body)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }

                    HStack {
                        Text(plan.createdAt, format: .dateTime.month().day().year())
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        Spacer()
                        if let count = plan.tasks?.count, count > 0 {
                            Text("\(done.count)/\(count) done")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.card(colorScheme, style: style))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

                // Add task button
                Button { showingAddTask = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Task")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                }

                // Active tasks
                if !active.isEmpty {
                    Text("Tasks")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .padding(.top, Theme.Spacing.sm)

                    ForEach(active) { task in
                        TaskRow(task: task, colorScheme: colorScheme, style: style)
                            .onTapGesture { taskToEdit = task }
                    }
                }

                // Completed tasks
                if !done.isEmpty {
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .padding(.top, Theme.Spacing.sm)

                    ForEach(done) { task in
                        TaskRow(task: task, colorScheme: colorScheme, style: style)
                            .onTapGesture { taskToEdit = task }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 100)
        }
        .background(Theme.Colors.background(colorScheme, style: style))
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
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
            EditPlanSheet(plan: plan)
        }
        .sheet(isPresented: $showingAddTask) {
            TaskFormSheet(plan: plan)
        }
        .sheet(item: $taskToEdit) { task in
            TaskFormSheet(plan: plan, existingTask: task)
        }
        .alert("Delete Plan?", isPresented: $showingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(plan)
                dismiss()
            }
        } message: {
            Text("This will delete the plan and all tasks.")
        }
    }

    private var missingView: some View {
        ContentUnavailableView("Plan not found", systemImage: "folder")
            .navigationTitle("Plan")
    }
}

// MARK: - Task Row

private struct TaskRow: View {
    @Bindable var task: Task
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Button { task.isDone.toggle() } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Theme.Colors.success(colorScheme, style: style) : Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? Theme.Colors.textSecondary(colorScheme, style: style) : Theme.Colors.textPrimary(colorScheme, style: style))

                if let detail = task.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if task.importance >= 4 {
                        HStack(spacing: 2) {
                            ForEach(0..<min(task.importance - 2, 3), id: \.self) { _ in
                                Image(systemName: "exclamationmark")
                                    .font(.caption2)
                            }
                        }
                        .foregroundStyle(Theme.Colors.caution(colorScheme, style: style))
                    }

                    if let due = task.dueDate {
                        Text(due, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(due < Date() ? Theme.Colors.destructive(colorScheme, style: style) : Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                }
            }

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

// MARK: - Edit Plan Sheet

private struct EditPlanSheet: View {
    @Bindable var plan: Plan
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var detail: String

    init(plan: Plan) {
        self.plan = plan
        _title = State(initialValue: plan.title)
        _detail = State(initialValue: plan.detail ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $detail, axis: .vertical)
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        plan.title = title
                        plan.detail = detail.isEmpty ? nil : detail
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Task Form Sheet

private struct TaskFormSheet: View {
    let plan: Plan
    let existingTask: Task?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var detail: String
    @State private var importance: Int
    @State private var hasDue: Bool
    @State private var dueDate: Date

    init(plan: Plan, existingTask: Task? = nil) {
        self.plan = plan
        self.existingTask = existingTask
        _title = State(initialValue: existingTask?.title ?? "")
        _detail = State(initialValue: existingTask?.detail ?? "")
        _importance = State(initialValue: existingTask?.importance ?? 3)
        _hasDue = State(initialValue: existingTask?.dueDate != nil)
        _dueDate = State(initialValue: existingTask?.dueDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task", text: $title)
                TextField("Notes (optional)", text: $detail, axis: .vertical)

                Picker("Priority", selection: $importance) {
                    Text("Low").tag(1)
                    Text("Normal").tag(3)
                    Text("High").tag(4)
                    Text("Urgent").tag(5)
                }

                Toggle("Due date", isOn: $hasDue)
                if hasDue {
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func save() {
        if let task = existingTask {
            task.title = title
            task.detail = detail.isEmpty ? nil : detail
            task.importance = importance
            task.dueDate = hasDue ? dueDate : nil
        } else {
            let task = Task(
                title: title,
                detail: detail.isEmpty ? nil : detail,
                importance: importance,
                dueDate: hasDue ? dueDate : nil,
                plan: plan
            )
            modelContext.insert(task)
        }
    }
}

#Preview {
    let container = PersistenceController.preview
    let plan = Plan(title: "Sample", detail: "A test plan")
    container.mainContext.insert(plan)

    return NavigationStack {
        PlanDetailView(planID: plan.id)
    }
    .modelContainer(container)
    .environmentObject(ThemeManager.shared)
}
