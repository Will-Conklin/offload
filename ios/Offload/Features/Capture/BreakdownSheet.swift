// Purpose: Smart Task Breakdown sheet — granularity slider, step preview, save as plan.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

// MARK: - ViewModel

/// Manages the breakdown generation and editing flow for a single item.
@Observable
@MainActor
final class BreakdownSheetViewModel {

    enum Phase: Equatable {
        case configure
        case preview
    }

    struct EditableBreakdownStep: Identifiable {
        let id: UUID
        var title: String

        init(title: String) {
            id = UUID()
            self.title = title
        }
    }

    var granularity: Int = 3
    var steps: [EditableBreakdownStep] = []
    var planName: String = ""
    var isGenerating: Bool = false
    var phase: Phase = .configure

    /// True when `planName` is blank after trimming whitespace.
    var isPlanNameEmpty: Bool {
        planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Requests a breakdown from the service and transitions to the preview phase.
    /// - Parameters:
    ///   - inputText: The item content to break down.
    ///   - service: The breakdown service to call.
    func generate(inputText: String, using service: BreakdownService) async throws {
        isGenerating = true
        defer { isGenerating = false }

        let result = try await service.generateBreakdown(
            inputText: inputText,
            granularity: granularity,
            contextHints: [],
            templateIds: []
        )

        steps = result.steps.map { EditableBreakdownStep(title: $0.title) }

        if planName.isEmpty {
            planName = String(inputText.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        phase = .preview
    }

    /// Saves the approved breakdown steps as a new structured plan collection.
    func save(
        itemRepository: ItemRepository,
        collectionRepository: CollectionRepository,
        collectionItemRepository: CollectionItemRepository
    ) throws {
        let trimmedName = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("Plan name cannot be empty.")
        }

        let collection = try collectionRepository.create(name: trimmedName, isStructured: true)

        var position = 0
        for step in steps {
            let trimmedTitle = step.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }
            let item = try itemRepository.create(type: "task", content: trimmedTitle)
            _ = try collectionItemRepository.addItemToCollection(
                itemId: item.id,
                collectionId: collection.id,
                position: position,
                parentId: nil
            )
            position += 1
        }
    }
}

// MARK: - Sheet View

/// Presents the Smart Task Breakdown experience: configure granularity, generate steps, edit, then save as a plan.
struct BreakdownSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.breakdownService) private var breakdownService
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.collectionItemRepository) private var collectionItemRepository
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var viewModel = BreakdownSheetViewModel()
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Surface.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        itemPreviewSection
                            .padding(.top, Theme.Spacing.sm)

                        granularitySection

                        phaseContent
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("Break Down")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
                if viewModel.phase == .preview {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                                viewModel.phase = .configure
                            }
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    }
                }
            }
        }
        .errorToasts(errorPresenter)
    }

    // MARK: - Phase content

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .configure:
            generateButtonSection
        case .preview:
            stepsSection
            planNameSection
            saveButtonSection
        }
    }

    // MARK: - Sections

    private var itemPreviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Task")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
                Text(item.content)
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
            }
            .accessibilityLabel("Task: \(item.content)")
        }
    }

    private var granularitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Steps")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                Spacer()
                Text("\(viewModel.granularity)")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    .accessibilityHidden(true)
            }

            Slider(value: Binding(
                get: { Double(viewModel.granularity) },
                set: { viewModel.granularity = Int($0.rounded()) }
            ), in: 1...5, step: 1)
            .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
            .accessibilityLabel("Number of steps")
            .accessibilityValue("\(viewModel.granularity) steps")

            HStack {
                Text("Fewer")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                Spacer()
                Text("More")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var generateButtonSection: some View {
        if viewModel.isGenerating {
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
                Text("Generating…")
                    .font(Theme.Typography.buttonLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .accessibilityLabel("Generating steps, please wait")
        } else {
            FloatingActionButton(title: "Generate Steps", iconName: Icons.breakdown) {
                Task {
                    do {
                        try await viewModel.generate(inputText: item.content, using: breakdownService)
                    } catch {
                        errorPresenter.present(error)
                    }
                }
            }
            .accessibilityLabel("Generate steps")
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Steps — tap to edit")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.xs) {
                ForEach($viewModel.steps) { $step in
                    BreakdownStepRow(step: $step, colorScheme: colorScheme, style: style)
                }
            }
        }
    }

    private var planNameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Plan Name")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

            TextField("Name your plan", text: $viewModel.planName)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                .padding(Theme.Spacing.md)
                .background(Theme.Surface.card(colorScheme, style: style))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .accessibilityLabel("Plan name")
                .accessibilityHint("Name for the new plan that will be created from these steps")
        }
    }

    private var saveButtonSection: some View {
        FloatingActionButton(title: "Save as Plan", iconName: Icons.plans) {
            saveBreakdown()
        }
        .disabled(viewModel.isPlanNameEmpty)
        .accessibilityLabel("Save as plan")
        .accessibilityHint("Creates a new plan with the generated steps")
    }

    // MARK: - Actions

    private func saveBreakdown() {
        do {
            try viewModel.save(
                itemRepository: itemRepository,
                collectionRepository: collectionRepository,
                collectionItemRepository: collectionItemRepository
            )
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Step Row

private struct BreakdownStepRow: View {
    @Binding var step: BreakdownSheetViewModel.EditableBreakdownStep

    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        CardSurface(fill: Theme.Surface.card(colorScheme, style: style)) {
            TextField("Step description", text: $step.title, axis: .vertical)
                .font(Theme.Typography.cardBody)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                .lineLimit(2...)
                .padding(Theme.Spacing.md)
        }
        .accessibilityLabel("Step: \(step.title)")
        .accessibilityHint("Tap to edit this step")
    }
}
