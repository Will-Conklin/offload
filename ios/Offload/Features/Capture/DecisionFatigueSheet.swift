// Purpose: Decision Fatigue Reducer sheet — surfaces 2-3 good-enough options, optional refinement questions.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

// MARK: - ViewModel

/// Manages the decision-fatigue reduction flow for a single capture item.
@Observable
@MainActor
final class DecisionFatigueSheetViewModel {

    enum Phase: Equatable {
        case configure
        case options
        case decided(Int) // index of chosen option
    }

    var options: [DecisionOption] = []
    var clarifyingQuestions: [String] = []
    var answers: [String] = []
    var isGenerating: Bool = false
    var phase: Phase = .configure

    /// True when there are unanswered clarifying questions from a prior generation.
    var hasPendingQuestions: Bool {
        !clarifyingQuestions.isEmpty
    }

    /// Pairs of questions and their current answer strings.
    var questionAnswerPairs: [(question: String, answer: String)] {
        clarifyingQuestions.enumerated().map { index, question in
            (question: question, answer: index < answers.count ? answers[index] : "")
        }
    }

    /// Builds clarifying answers from questions + user-entered answers.
    var clarifyingAnswers: [DecisionClarifyingAnswer] {
        clarifyingQuestions.enumerated().compactMap { index, question in
            let answer = index < answers.count ? answers[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            guard !answer.isEmpty else { return nil }
            return DecisionClarifyingAnswer(question: question, answer: answer)
        }
    }

    /// Fetches decision options, optionally with clarifying answers.
    /// - Parameters:
    ///   - inputText: The item content to evaluate.
    ///   - service: The decision fatigue service to call.
    func getOptions(inputText: String, using service: DecisionFatigueService) async throws {
        isGenerating = true
        defer { isGenerating = false }

        let result = try await service.suggestDecisions(
            inputText: inputText,
            contextHints: [],
            clarifyingAnswers: clarifyingAnswers
        )

        options = result.options
        clarifyingQuestions = result.clarifyingQuestions
        // Reset answers to match new questions, preserving any previously-entered values
        let existingAnswers = answers
        answers = clarifyingQuestions.enumerated().map { index, _ in
            index < existingAnswers.count ? existingAnswers[index] : ""
        }

        phase = .options
    }

    /// Selects the recommended option (or first) and transitions to decided phase.
    func justPickForMe() {
        let pickedIndex = options.firstIndex(where: { $0.isRecommended }) ?? 0
        phase = .decided(pickedIndex)
    }

    /// Updates an answer at the given question index.
    func setAnswer(_ text: String, at index: Int) {
        while answers.count <= index {
            answers.append("")
        }
        answers[index] = text
    }
}

// MARK: - Sheet View

/// Presents the Decision Fatigue Reducer: surfaces 2–3 good-enough options with an optional "Just pick for me" mode.
struct DecisionFatigueSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.decisionFatigueService) private var decisionFatigueService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var viewModel = DecisionFatigueSheetViewModel()
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

                        phaseContent
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("Get Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
                if case .options = viewModel.phase {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Refine") {
                            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                                viewModel.phase = .configure
                            }
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                        .accessibilityLabel("Refine options")
                        .accessibilityHint("Answer clarifying questions to get more tailored options")
                    }
                }
                if case .decided = viewModel.phase {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("All Options") {
                            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                                viewModel.phase = .options
                            }
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                        .accessibilityLabel("Show all options")
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
            if viewModel.hasPendingQuestions {
                clarifyingQuestionsSection
            }
            getOptionsButtonSection

        case .options:
            optionsSection
            justPickSection

        case .decided(let index):
            decidedSection(index: index)
        }
    }

    // MARK: - Sections

    private var itemPreviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Capture")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
                Text(item.content)
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
            }
            .accessibilityLabel("Capture: \(item.content)")
        }
    }

    @ViewBuilder
    private var clarifyingQuestionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Optional — answer to get tailored options")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(viewModel.clarifyingQuestions.enumerated()), id: \.offset) { index, question in
                    ClarifyingQuestionRow(
                        question: question,
                        answer: Binding(
                            get: { index < viewModel.answers.count ? viewModel.answers[index] : "" },
                            set: { viewModel.setAnswer($0, at: index) }
                        ),
                        colorScheme: colorScheme,
                        style: style
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var getOptionsButtonSection: some View {
        if viewModel.isGenerating {
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
                Text("Finding options…")
                    .font(Theme.Typography.buttonLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .accessibilityLabel("Finding options, please wait")
        } else {
            FloatingActionButton(
                title: viewModel.hasPendingQuestions ? "Get Tailored Options" : "Get Options",
                iconName: Icons.decisionFatigue
            ) {
                Task {
                    do {
                        try await viewModel.getOptions(
                            inputText: item.content,
                            using: decisionFatigueService
                        )
                    } catch {
                        errorPresenter.present(error)
                    }
                }
            }
            .accessibilityLabel("Get options")
            .accessibilityHint("Surfaces 2 to 3 good-enough recommendations for this capture")
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Good-enough options")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(viewModel.options.enumerated()), id: \.offset) { index, option in
                    DecisionOptionCard(
                        option: option,
                        colorIndex: index,
                        colorScheme: colorScheme,
                        style: style
                    )
                }
            }
        }
    }

    private var justPickSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Can't decide?")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            Button {
                withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                    viewModel.justPickForMe()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    AppIcon(name: Icons.decisionFatigue, size: 16)
                    Text("Just pick for me")
                        .font(Theme.Typography.buttonLabel)
                }
                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .strokeBorder(Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Just pick for me")
            .accessibilityHint("Selects the recommended option for you")
        }
    }

    @ViewBuilder
    private func decidedSection(index: Int) -> some View {
        if index < viewModel.options.count {
            let option = viewModel.options[index]
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Go with this")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    .accessibilityHidden(true)

                CardSurface(
                    fill: Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.12),
                    showsBorder: true
                ) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.sm) {
                            AppIcon(name: Icons.checkCircleFilled, size: 20)
                                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                            Text(option.title)
                                .font(Theme.Typography.cardTitle)
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        }

                        Text(option.description)
                            .font(Theme.Typography.cardBody)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
                }
                .accessibilityLabel("Recommended: \(option.title). \(option.description)")
            }

            Text("All options are suggestions only — you're in charge.")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.xs)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Option Card

private struct DecisionOptionCard: View {
    let option: DecisionOption
    let colorIndex: Int
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        CardSurface(
            fill: Theme.Colors.cardColor(index: colorIndex, colorScheme, style: style),
            showsBorder: option.isRecommended
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                    Text(option.title)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if option.isRecommended {
                        Text("Best match")
                            .font(Theme.Typography.badge)
                            .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Theme.Colors.accentPrimary(colorScheme, style: style))
                            )
                    }
                }

                Text(option.description)
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
        }
        .accessibilityLabel("\(option.title)\(option.isRecommended ? ", best match" : ""). \(option.description)")
    }
}

// MARK: - Clarifying Question Row

private struct ClarifyingQuestionRow: View {
    let question: String
    @Binding var answer: String
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(question)
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

            TextField("Optional answer", text: $answer, axis: .vertical)
                .font(Theme.Typography.cardBody)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                .lineLimit(1...3)
                .padding(Theme.Spacing.md)
                .background(Theme.Surface.card(colorScheme, style: style))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .accessibilityLabel("Answer for: \(question)")
                .accessibilityHint("Optional — leave blank to skip")
        }
    }
}
