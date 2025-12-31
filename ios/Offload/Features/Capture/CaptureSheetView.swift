//
//  CaptureSheetView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

struct CaptureSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var rawText: String = ""
    @State private var showingPermissionAlert = false
    private let voiceService = VoiceRecordingService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Capture") {
                    HStack(alignment: .top, spacing: 12) {
                        TextField("What's on your mind?", text: $rawText, axis: .vertical)
                            .lineLimit(3...10)

                        VStack(spacing: 8) {
                            Button(action: handleVoiceButtonTap) {
                                Image(systemName: voiceService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(voiceService.isRecording ? .red : .blue)
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
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                if !newValue.isEmpty {
                    rawText = newValue
                }
            }
        }
    }

    private func handleVoiceButtonTap() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
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

        let entry = BrainDumpEntry(
            rawText: rawText.trimmingCharacters(in: .whitespacesAndNewlines),
            inputType: voiceService.transcribedText.isEmpty ? .text : .voice,
            source: .app,
            lifecycleState: .raw
        )
        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    CaptureSheetView()
        .modelContainer(PersistenceController.preview)
}
