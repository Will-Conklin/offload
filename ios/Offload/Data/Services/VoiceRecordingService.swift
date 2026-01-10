//
//  VoiceRecordingService.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//

import Foundation
import OSLog
import AVFoundation
import Speech
import Observation

@Observable
final class VoiceRecordingService: @unchecked Sendable {
    // MARK: - Published State

    var isRecording = false
    var isTranscribing = false
    var transcribedText = ""
    var errorMessage: String?
    var recordingDuration: TimeInterval = 0

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recordingTimer: Timer?
    private var cachedMicrophonePermission: Bool?
    private var cachedSpeechPermission: Bool?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        if checkPermissions() {
            return true
        }

        let microphoneAuthorized = await requestMicrophonePermission()
        let speechAuthorized = await requestSpeechRecognitionPermission()

        cachedMicrophonePermission = microphoneAuthorized
        cachedSpeechPermission = speechAuthorized

        return microphoneAuthorized && speechAuthorized
    }

    func checkPermissions() -> Bool {
        if let microphonePermission = cachedMicrophonePermission,
           let speechPermission = cachedSpeechPermission {
            return microphonePermission && speechPermission
        }

        let microphoneStatus = AVAudioApplication.shared.recordPermission
        cachedMicrophonePermission = (microphoneStatus == .granted)

        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        cachedSpeechPermission = (speechStatus == .authorized)

        return (cachedMicrophonePermission ?? false) && (cachedSpeechPermission ?? false)
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Recording Controls

    func startRecording() async throws {
        // Reset state
        transcribedText = ""
        errorMessage = nil
        recordingDuration = 0

        // Check permissions
        let hasPermissions = await requestPermissions()
        guard hasPermissions else {
            errorMessage = "Microphone and speech recognition permissions are required"
            throw RecordingError.permissionDenied
        }

        // Check speech recognizer availability
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available"
            throw RecordingError.recognizerNotAvailable
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            throw RecordingError.failedToCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Offline-first

        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            errorMessage = "Unable to create audio engine"
            throw RecordingError.failedToCreateAudioEngine
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        isTranscribing = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }

            if error != nil {
                self.stopRecording()
            }
        }

        // Start recording timer
        isRecording = true
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }

    func stopRecording() {
        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // Stop recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        // Reset state
        isRecording = false
        isTranscribing = false

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Log error but don't fail - audio session deactivation is non-critical
            AppLogger.voice.warning("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
        }

        // Cleanup
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }

    func cancelRecording() {
        transcribedText = ""
        stopRecording()
    }

    // MARK: - Error Types

    enum RecordingError: LocalizedError {
        case permissionDenied
        case recognizerNotAvailable
        case failedToCreateRequest
        case failedToCreateAudioEngine
        case recordingFailed

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone and speech recognition permissions are required"
            case .recognizerNotAvailable:
                return "Speech recognition is not available on this device"
            case .failedToCreateRequest:
                return "Failed to initialize speech recognition"
            case .failedToCreateAudioEngine:
                return "Failed to initialize audio recording"
            case .recordingFailed:
                return "Recording failed unexpectedly"
            }
        }
    }
}
