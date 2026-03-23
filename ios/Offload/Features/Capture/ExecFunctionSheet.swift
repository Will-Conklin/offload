// Purpose: Executive Function Prompts sheet — conversational scaffolding for stuck users.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

// MARK: - ViewModel

/// Manages the executive function prompts flow for a single capture item.
@Observable
@MainActor
final class ExecFunctionSheetViewModel {

    enum Phase: Equatable {
        case configure
        case strategies
        case feedback(Int) // index of selected strategy
    }

    var detectedChallenge: ExecFunctionChallengeType?
    var strategies: [ExecFunctionStrategy] = []
    var encouragement: String = ""
    var isGenerating: Bool = false
    var phase: Phase = .configure

    /// Generates executive function strategies for the input text.
    func getStrategies(
        inputText: String,
        service: ExecFunctionService,
        effectivenessStore: StrategyEffectivenessStore
    ) async throws {
        isGenerating = true
        defer { isGenerating = false }

        let result = try await service.promptExecFunction(
            inputText: inputText,
            contextHints: [],
            strategyHistory: effectivenessStore.strategyHistory()
        )

        detectedChallenge = ExecFunctionChallengeType(rawValue: result.detectedChallenge)
        strategies = result.strategies
        encouragement = result.encouragement
        phase = .strategies
    }

    /// Selects a strategy and moves to the feedback phase.
    func selectStrategy(at index: Int) {
        phase = .feedback(index)
    }
}

// MARK: - Sheet View

/// Presents executive function scaffolding: detects challenge type, suggests micro-strategies,
/// and collects effectiveness feedback.
struct ExecFunctionSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.execFunctionService) private var execFunctionService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var viewModel = ExecFunctionSheetViewModel()
    @State private var errorPresenter = ErrorPresenter()
    @State private var effectivenessStore = StrategyEffectivenessStore()

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
            .navigationTitle("I'm Stuck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
                if case .strategies = viewModel.phase {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Try Again") {
                            Task {
                                do {
                                    try await viewModel.getStrategies(
                                        inputText: item.content,
                                        service: execFunctionService,
                                        effectivenessStore: effectivenessStore
                                    )
                                } catch {
                                    errorPresenter.present(error)
                                }
                            }
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                        .accessibilityLabel("Try different strategies")
                    }
                }
                if case .feedback = viewModel.phase {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("All Strategies") {
                            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                                viewModel.phase = .strategies
                            }
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                        .accessibilityLabel("Show all strategies")
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
            getStrategiesButtonSection

        case .strategies:
            challengeBadge
            encouragementSection
            strategiesSection

        case .feedback(let index):
            feedbackSection(index: index)
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
    private var getStrategiesButtonSection: some View {
        if viewModel.isGenerating {
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
                Text("Finding strategies…")
                    .font(Theme.Typography.buttonLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .accessibilityLabel("Finding strategies, please wait")
        } else {
            FloatingActionButton(
                title: "Help Me Get Unstuck",
                iconName: Icons.execFunction
            ) {
                Task {
                    do {
                        try await viewModel.getStrategies(
                            inputText: item.content,
                            service: execFunctionService,
                            effectivenessStore: effectivenessStore
                        )
                    } catch {
                        errorPresenter.present(error)
                    }
                }
            }
            .accessibilityLabel("Help me get unstuck")
            .accessibilityHint("Suggests strategies based on what's blocking you")
        }
    }

    @ViewBuilder
    private var challengeBadge: some View {
        if let challenge = viewModel.detectedChallenge {
            HStack(spacing: Theme.Spacing.xs) {
                AppIcon(name: challenge.icon, size: 14)
                Text(challenge.displayName)
                    .font(Theme.Typography.badge)
            }
            .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Theme.Colors.accentSecondary(colorScheme, style: style))
            )
            .accessibilityLabel("Detected challenge: \(challenge.displayName)")
        }
    }

    @ViewBuilder
    private var encouragementSection: some View {
        if !viewModel.encouragement.isEmpty {
            Text(viewModel.encouragement)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.Spacing.md)
                .accessibilityLabel(viewModel.encouragement)
        }
    }

    private var strategiesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Try one of these")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(viewModel.strategies.enumerated()), id: \.offset) { index, strategy in
                    StrategyCard(
                        strategy: strategy,
                        colorIndex: index,
                        colorScheme: colorScheme,
                        style: style
                    ) {
                        withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                            viewModel.selectStrategy(at: index)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackSection(index: Int) -> some View {
        if index < viewModel.strategies.count {
            let strategy = viewModel.strategies[index]

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Selected strategy detail
                CardSurface(
                    fill: Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.12),
                    showsBorder: true
                ) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.sm) {
                            AppIcon(name: Icons.checkCircleFilled, size: 20)
                                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                            Text(strategy.title)
                                .font(Theme.Typography.cardTitle)
                                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        }

                        Text(strategy.actionPrompt)
                            .font(Theme.Typography.cardBody)
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
                }
                .accessibilityLabel("Strategy: \(strategy.title). \(strategy.actionPrompt)")

                // Feedback buttons
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Was this helpful?")
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                    HStack(spacing: Theme.Spacing.md) {
                        feedbackButton(
                            title: "Helpful",
                            iconName: "hand.thumbsup",
                            isPositive: true
                        ) {
                            recordFeedback(strategy: strategy, thumbsUp: true)
                        }

                        feedbackButton(
                            title: "Not helpful",
                            iconName: "hand.thumbsdown",
                            isPositive: false
                        ) {
                            recordFeedback(strategy: strategy, thumbsUp: false)
                        }
                    }
                }

                Text("All strategies are suggestions — you're in charge.")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
    }

    private func feedbackButton(title: String, iconName: String, isPositive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                AppIcon(name: iconName, size: 16)
                Text(title)
                    .font(Theme.Typography.buttonLabel)
            }
            .foregroundStyle(
                isPositive
                    ? Theme.Colors.accentPrimary(colorScheme, style: style)
                    : Theme.Colors.textSecondary(colorScheme, style: style)
            )
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(
                        isPositive
                            ? Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.1)
                            : Theme.Surface.card(colorScheme, style: style)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .strokeBorder(
                        isPositive
                            ? Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.3)
                            : Theme.Colors.borderMuted(colorScheme, style: style),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func recordFeedback(strategy: ExecFunctionStrategy, thumbsUp: Bool) {
        effectivenessStore.recordFeedback(
            strategyId: strategy.strategyId,
            challengeType: strategy.challengeType,
            thumbsUp: thumbsUp
        )
        effectivenessStore.registerPendingCompletionCheck(
            strategyId: strategy.strategyId,
            challengeType: strategy.challengeType,
            itemId: item.id.uuidString
        )
        dismiss()
    }
}

// MARK: - Strategy Card

private struct StrategyCard: View {
    let strategy: ExecFunctionStrategy
    let colorIndex: Int
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            CardSurface(fill: Theme.Colors.cardColor(index: colorIndex, colorScheme, style: style)) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(strategy.title)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                    Text(strategy.description)
                        .font(Theme.Typography.cardBody)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                    HStack(spacing: Theme.Spacing.xs) {
                        AppIcon(name: "arrow.right.circle", size: 14)
                        Text(strategy.actionPrompt)
                            .font(Theme.Typography.metadata)
                    }
                    .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.md)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(strategy.title). \(strategy.description)")
        .accessibilityHint("Tap to try this strategy: \(strategy.actionPrompt)")
    }
}
