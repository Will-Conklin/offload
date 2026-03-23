// Purpose: AI-assisted draft sheet for communication items.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

struct CommunicationDraftSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var draftText: String = ""
    @State private var isLoading = false
    @State private var hasGenerated = false
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }
    private var commMeta: CommunicationMetadata? { item.communicationMetadata }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        contextCard
                        draftCard
                    }
                    .padding(Theme.Spacing.md)
                }

                Spacer()
                bottomBar
            }
            .background(Theme.Gradients.deepBackground(colorScheme).ignoresSafeArea())
            .navigationTitle("Draft Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .errorToasts(errorPresenter)
    }

    private var contextCard: some View {
        InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if let channel = commMeta?.channel {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: channel.icon)
                            .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                        Text(channel.displayName)
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                        if let name = commMeta?.contactName {
                            Text("to \(name)")
                                .font(Theme.Typography.metadata)
                                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                        }
                    }
                }

                Text(item.content)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
            }
        }
    }

    private var draftCard: some View {
        InputCard(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("DRAFT")
                    .font(Theme.Typography.metadata)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(Theme.Spacing.xl)
                        Spacer()
                    }
                } else if draftText.isEmpty {
                    Text("Tap \"Generate Draft\" to create a message based on your notes.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                } else {
                    TextEditor(text: $draftText)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface(colorScheme, style: style))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                                .stroke(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.35), lineWidth: 0.6)
                        )
                }
            }
        }
    }

    private var bottomBar: some View {
        ActionBarContainer(fill: Theme.Colors.cardColor(index: 2, colorScheme, style: style)) {
            HStack(spacing: Theme.Spacing.md) {
                Button(action: generateDraft) {
                    Text(hasGenerated ? "Regenerate" : "Generate Draft")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.primary(colorScheme, style: style))
                        .clipShape(Capsule())
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1)

                Spacer()

                if !draftText.isEmpty {
                    Button(action: useDraft) {
                        Text("Use Draft")
                            .font(Theme.Typography.buttonLabel)
                            .foregroundStyle(Theme.Colors.buttonDarkText(colorScheme, style: style))
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.buttonDark(colorScheme))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    private func generateDraft() {
        guard let channel = commMeta?.channel else { return }
        isLoading = true

        _Concurrency.Task {
            do {
                let service = DefaultCommunicationDraftService(
                    backendClient: NetworkAIBackendClient(),
                    consentStore: UserDefaultsCloudAIConsentStore(),
                    usageStore: QuotaStore.shared
                )
                let result = try await service.draftCommunication(
                    inputText: item.content,
                    channel: channel.rawValue,
                    contactName: commMeta?.contactName,
                    contextHints: []
                )
                draftText = result.draftText
                hasGenerated = true
            } catch {
                errorPresenter.present(error)
            }
            isLoading = false
        }
    }

    private func useDraft() {
        guard let channel = commMeta?.channel,
              let contactValue = commMeta?.contactValue
        else {
            UIPasteboard.general.string = draftText
            dismiss()
            return
        }

        CommunicationActionService.performAction(
            channel: channel,
            contactValue: contactValue,
            subject: item.content,
            body: draftText
        )
        dismiss()
    }
}
