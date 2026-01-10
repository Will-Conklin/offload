//
//  CaptureSheetView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Quick capture interface with voice and text input.
//  Minimizes friction - saves to inbox immediately, no forced organization.
//

import SwiftUI
import SwiftData
import UIKit

struct CaptureSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var rawText: String = ""
    @State private var showingPermissionAlert = false
    @State private var voiceService = VoiceRecordingService()
    @State private var workflowService: CaptureWorkflowService?
    @State private var preRecordingText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Capture") {
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        TextField("What's on your mind?", text: $rawText, axis: .vertical)
                            .lineLimit(3...10)

                        VStack(spacing: Theme.Spacing.sm) {
                            Button(action: handleVoiceButtonTap) {
                                Image(systemName: voiceService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(voiceService.isRecording ? Theme.Colors.destructive(colorScheme) : Theme.Colors.accentPrimary(colorScheme))
                            }
                            .buttonStyle(.plain)

                            if voiceService.isRecording {
                                Text(formatDuration(voiceService.recordingDuration))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if voiceService.isTranscribing && !voiceService.transcribedText.isEmpty {
                        Text("Transcribing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = voiceService.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Theme.Typography.errorText)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme))
                    }
                }

                if let errorMessage = workflowService?.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Theme.Typography.errorText)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme))
                    }
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Theme.Materials.glass)
            .overlay(
                Theme.Materials.glassOverlay(colorScheme)
                    .opacity(Theme.Materials.glassOverlayOpacity)
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if voiceService.isRecording {
                            voiceService.cancelRecording()
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveThought()
                    }
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || workflowService?.isProcessing == true)
                }
            }
            .alert("Permissions Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            } message: {
                Text("Please enable microphone and speech recognition permissions in Settings to use voice capture.")
            }
            .onChange(of: voiceService.transcribedText) { _, newValue in
                guard !newValue.isEmpty else { return }

                let separator = preRecordingText.isEmpty || preRecordingText.hasSuffix(" ") ? "" : " "
                rawText = preRecordingText + separator + newValue
            }
            .task {
                if workflowService == nil {
                    workflowService = CaptureWorkflowService(modelContext: modelContext)
                }
            }
        }
    }

    private func handleVoiceButtonTap() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            preRecordingText = rawText
            _Concurrency.Task {
                do {
                    try await voiceService.startRecording()
                } catch {
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func saveThought() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        }

        guard let workflowService = workflowService else {
            // Fallback: if service not initialized, create entry directly
            let entry = CaptureEntry(
                rawText: rawText.trimmingCharacters(in: .whitespacesAndNewlines),
                inputType: voiceService.transcribedText.isEmpty ? .text : .voice,
                source: .app,
                lifecycleState: .raw
            )
            modelContext.insert(entry)
            dismiss()
            return
        }

        _Concurrency.Task { @MainActor in
            do {
                _ = try await workflowService.captureEntry(
                    rawText: rawText.trimmingCharacters(in: .whitespacesAndNewlines),
                    inputType: voiceService.transcribedText.isEmpty ? .text : .voice,
                    source: .app
                )
                dismiss()
            } catch {
                // Error is already set in workflowService.errorMessage
                // Don't dismiss on error so user can see the error message
            }
        }
    }
}

#Preview {
    CaptureSheetView()
        .modelContainer(PersistenceController.preview)
}
