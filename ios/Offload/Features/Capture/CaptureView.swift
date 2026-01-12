//
//  CaptureView.swift
//  Offload
//
//  Minimal capture: text + mic + photo, optional tags/category/priority
//

import SwiftUI
import SwiftData
import PhotosUI

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var text: String = ""
    @State private var isPriority: Bool = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTags = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var voiceService = VoiceRecordingService()
    @State private var preRecordingText = ""
    @State private var showingPermissionAlert = false

    @FocusState private var isFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Text input
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    TextEditor(text: $text)
                        .font(.body)
                        .frame(minHeight: 100)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty && !isFocused {
                                Text("What's on your mind?")
                                    .font(.body)
                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
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
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }

                    // Photo preview
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                            Button {
                                self.photoData = nil
                                self.selectedPhoto = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
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

                Spacer()

                // Bottom bar
                HStack(spacing: Theme.Spacing.md) {
                    // Mic
                    Button(action: handleVoice) {
                        Image(systemName: voiceService.isRecording ? "stop.fill" : "mic")
                            .font(.title3)
                            .foregroundStyle(
                                voiceService.isRecording
                                    ? Theme.Colors.destructive(colorScheme, style: style)
                                    : Theme.Colors.textSecondary(colorScheme, style: style)
                            )
                            .frame(width: 44, height: 44)
                    }

                    // Photo
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: photoData != nil ? "photo.fill" : "photo")
                            .font(.title3)
                            .foregroundStyle(
                                photoData != nil
                                    ? Theme.Colors.primary(colorScheme, style: style)
                                    : Theme.Colors.textSecondary(colorScheme, style: style)
                            )
                            .frame(width: 44, height: 44)
                    }

                    // Tags
                    Button { showingTags = true } label: {
                        Image(systemName: selectedTags.isEmpty ? "tag" : "tag.fill")
                            .font(.title3)
                            .foregroundStyle(
                                selectedTags.isEmpty
                                    ? Theme.Colors.textSecondary(colorScheme, style: style)
                                    : Theme.Colors.primary(colorScheme, style: style)
                            )
                            .frame(width: 44, height: 44)
                    }

                    // Priority
                    Button { isPriority.toggle() } label: {
                        Image(systemName: isPriority ? "exclamationmark.circle.fill" : "exclamationmark.circle")
                            .font(.title3)
                            .foregroundStyle(
                                isPriority
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
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photoData == nil)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photoData == nil ? 0.5 : 1)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.surface(colorScheme, style: style))
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
            .onChange(of: selectedPhoto) { _, item in
                loadPhoto(item)
            }
            .onAppear { isFocused = true }
        }
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

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        _Concurrency.Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run { photoData = data }
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
            tags: selectedTags.map { $0.name },
            isStarred: isPriority
        )
        // TODO: Store photoData in metadata when needed
        modelContext.insert(item)
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
                                    Image(systemName: "checkmark")
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
    CaptureView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
