//
//  CaptureComposeView.swift
//  Offload
//
//  Minimal capture: text + mic + attachment, optional tags/starred
//

import SwiftUI
import SwiftData
import UIKit

// AGENT NAV
// - State
// - Layout
// - Input
// - Bottom Bar
// - Media
// - Save

struct CaptureComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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

    @FocusState private var isFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            captureContent
        }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if voiceService.isRecording { voiceService.cancelRecording() }
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingTags) {
            TagSheet(selectedTags: $selectedTags, colorScheme: colorScheme, style: style)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            TextEditor(text: $text)
                .font(.body)
                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                .frame(minHeight: 100)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty && !isFocused {
                        Text("What's on your mind?")
                            .font(.body)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            // Recording indicator
            if voiceService.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.destructive(colorScheme, style: style))
                        .frame(width: 8, height: 8)
                    Text(formatDuration(voiceService.recordingDuration))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                }
            }

            // Attachment preview
            if let attachmentData, let uiImage = UIImage(data: attachmentData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                    Button {
                        self.attachmentData = nil
                    } label: {
                        AppIcon(name: Icons.closeCircleFilled, size: 18)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(4)
                }
            }

            // Tags preview
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedTags) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.card(colorScheme, style: style))
    }

    private var bottomBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Mic
            Button(action: handleVoice) {
                AppIcon(
                    name: voiceService.isRecording ? Icons.stopFilled : Icons.microphone,
                    size: 20
                )
                    .foregroundStyle(
                        voiceService.isRecording
                            ? Theme.Colors.destructive(colorScheme, style: style)
                            : Theme.Colors.textSecondary(colorScheme, style: style)
                    )
                    .frame(width: 44, height: 44)
            }

            // Attachment
            Button { showingAttachmentSource = true } label: {
                AppIcon(
                    name: attachmentData != nil ? Icons.cameraFilled : Icons.camera,
                    size: 20
                )
                    .foregroundStyle(
                        attachmentData != nil
                            ? Theme.Colors.primary(colorScheme, style: style)
                            : Theme.Colors.textSecondary(colorScheme, style: style)
                    )
                    .frame(width: 44, height: 44)
            }

            // Tags
            Button { showingTags = true } label: {
                AppIcon(
                    name: selectedTags.isEmpty ? Icons.tag : Icons.tagFilled,
                    size: 20
                )
                    .foregroundStyle(
                        selectedTags.isEmpty
                            ? Theme.Colors.textSecondary(colorScheme, style: style)
                            : Theme.Colors.primary(colorScheme, style: style)
                    )
                    .frame(width: 44, height: 44)
            }

            // Star
            Button { isStarred.toggle() } label: {
                AppIcon(
                    name: isStarred ? Icons.starFilled : Icons.star,
                    size: 20
                )
                    .foregroundStyle(
                        isStarred
                            ? Theme.Colors.caution(colorScheme, style: style)
                            : Theme.Colors.textSecondary(colorScheme, style: style)
                    )
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Save
            Button(action: save) {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.primary(colorScheme, style: style))
                    .clipShape(Capsule())
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.5)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface(colorScheme, style: style))
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

        let item = Item(
            type: nil, // Uncategorized capture
            content: text.trimmingCharacters(in: .whitespacesAndNewlines),
            attachmentData: attachmentData,
            tags: selectedTags.map { $0.name },
            isStarred: isStarred
        )
        modelContext.insert(item)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Tag Sheet

private struct TagSheet: View {
    @Binding var selectedTags: [Tag]
    let colorScheme: ColorScheme
    let style: ThemeStyle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var allTags: [Tag] = []
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New tag", text: $newName)
                        Button("Add") {
                            let tag = Tag(name: newName)
                            modelContext.insert(tag)
                            allTags.append(tag)
                            selectedTags.append(tag)
                            newName = ""
                        }
                        .disabled(newName.isEmpty)
                    }
                }

                Section("Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            if let i = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                selectedTags.remove(at: i)
                            } else {
                                selectedTags.append(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    AppIcon(name: Icons.check, size: 12)
                                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                let desc = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
                allTags = (try? modelContext.fetch(desc)) ?? []
            }
        }
    }
}

#Preview {
    CaptureComposeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
