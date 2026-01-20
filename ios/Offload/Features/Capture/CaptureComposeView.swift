// Purpose: Capture feature views and flows.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve low-friction capture UX and Item.type == nil semantics.

//  Minimal capture: text + mic + attachment, optional tags/starred

import SwiftUI
import SwiftData
import UIKit


struct CaptureComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var text: String = ""
    @State private var isStarred: Bool = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTags = false
    @State private var attachmentData: Data?
    @State private var showingAttachmentSource = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingCameraUnavailableAlert = false
    @State private var voiceService = VoiceRecordingService()
    @State private var preRecordingText = ""
    @State private var showingPermissionAlert = false
    @State private var errorPresenter = ErrorPresenter()

    @FocusState private var isFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            captureContent
        }
        .errorToasts(errorPresenter)
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var captureContent: some View {
        VStack(spacing: 0) {
            textInputSection
            Spacer()
            bottomBar
        }
        .background(Theme.Colors.background(colorScheme, style: style))
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if voiceService.isRecording { voiceService.cancelRecording() }
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingTags) {
            TagSelectionSheet(selectedTags: $selectedTags)
                .presentationDetents([.medium])
        }
        .alert("Mic Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) {}
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .onChange(of: voiceService.transcribedText) { _, newValue in
            guard !newValue.isEmpty else { return }
            let sep = preRecordingText.isEmpty || preRecordingText.hasSuffix(" ") ? "" : " "
            text = preRecordingText + sep + newValue
        }
        .onAppear { isFocused = true }
        .confirmationDialog("Add Attachment", isPresented: $showingAttachmentSource) {
            Button("Camera") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    imagePickerSource = .camera
                    showingImagePicker = true
                } else {
                    showingCameraUnavailableAlert = true
                }
            }
            Button("Photo Library") {
                imagePickerSource = .photoLibrary
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imagePickerSource, imageData: $attachmentData)
        }
        .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device does not support camera capture.")
        }
    }

    private var textInputSection: some View {
        InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                TextEditor(text: $text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                    .frame(minHeight: 120)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty && !isFocused {
                            Text("What's on your mind?")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.surface(colorScheme, style: style))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                            .stroke(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.35), lineWidth: 0.6)
                    )

                if voiceService.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.destructive(colorScheme, style: style))
                            .frame(width: 8, height: 8)
                        Text(formatDuration(voiceService.recordingDuration))
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                    }
                }

                if let attachmentData, let uiImage = UIImage(data: attachmentData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))

                        Button {
                            self.attachmentData = nil
                        } label: {
                            IconTile(
                                iconName: Icons.closeCircleFilled,
                                iconSize: 16,
                                tileSize: 32,
                                style: .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                            )
                            .shadow(
                                color: Theme.Shadows.ultraLight(colorScheme),
                                radius: Theme.Shadows.elevationUltraLight,
                                y: Theme.Shadows.offsetYUltraLight
                            )
                        }
                        .padding(4)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove attachment")
                    }
                }

                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(selectedTags) { tag in
                                TagPill(
                                    name: tag.name,
                                    color: Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var bottomBar: some View {
        ActionBarContainer(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
            HStack(spacing: Theme.Spacing.md) {
                Button(action: handleVoice) {
                    IconTile(
                        iconName: voiceService.isRecording ? Icons.stopFilled : Icons.microphone,
                        iconSize: 20,
                        tileSize: 44,
                        style: voiceService.isRecording
                            ? .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(voiceService.isRecording ? "Stop recording" : "Start voice capture")
                .accessibilityHint(
                    voiceService.isRecording
                        ? "Stops recording and keeps the transcription."
                        : "Records voice and transcribes into the capture."
                )

                Button { showingAttachmentSource = true } label: {
                    IconTile(
                        iconName: attachmentData != nil ? Icons.cameraFilled : Icons.camera,
                        iconSize: 20,
                        tileSize: 44,
                        style: attachmentData != nil
                            ? .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(attachmentData == nil ? "Add attachment" : "Change attachment")
                .accessibilityHint("Attach a photo to this capture.")

                Button { showingTags = true } label: {
                    IconTile(
                        iconName: selectedTags.isEmpty ? Icons.tag : Icons.tagFilled,
                        iconSize: 20,
                        tileSize: 44,
                        style: selectedTags.isEmpty
                            ? .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                            : .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectedTags.isEmpty ? "Add tags" : "Edit tags")
                .accessibilityHint("Select tags for this capture.")

                Button { isStarred.toggle() } label: {
                    IconTile(
                        iconName: isStarred ? Icons.starFilled : Icons.star,
                        iconSize: 20,
                        tileSize: 44,
                        style: isStarred
                            ? .primaryFilled(Theme.Colors.caution(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isStarred ? "Unstar capture" : "Star capture")
                .accessibilityHint("Toggle the star for this capture.")

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.buttonDark(colorScheme))
                        .clipShape(Capsule())
                        .shadow(
                            color: Theme.Shadows.ultraLight(colorScheme),
                            radius: Theme.Shadows.elevationUltraLight,
                            y: Theme.Shadows.offsetYUltraLight
                        )
                }
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    private func handleVoice() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            preRecordingText = text
            _Concurrency.Task {
                do { try await voiceService.startRecording() }
                catch { showingPermissionAlert = true }
            }
        }
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }

    private func save() {
        if voiceService.isRecording { voiceService.stopRecording() }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorPresenter.present(ValidationError("Capture content cannot be empty."))
            return
        }

        do {
            _ = try itemRepository.create(
                type: nil, // Uncategorized capture
                content: trimmedText,
                attachmentData: attachmentData,
                tags: selectedTags.map { $0.name },
                isStarred: isStarred
            )
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }
}

#Preview {
    CaptureComposeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
