// Purpose: Service-layer utilities.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep service APIs focused and testable.

import AVFoundation
import Foundation
import Observation
import OSLog
import Speech

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
            AppLogger.voice.debug("Permissions already granted")
            return true
        }

        AppLogger.voice.info("Requesting voice recording permissions")
        let microphoneAuthorized = await requestMicrophonePermission()
        let speechAuthorized = await requestSpeechRecognitionPermission()

        cachedMicrophonePermission = microphoneAuthorized
        cachedSpeechPermission = speechAuthorized

        let granted = microphoneAuthorized && speechAuthorized
        if granted {
            AppLogger.voice.info("Voice recording permissions granted")
        } else {
            AppLogger.voice.warning("Voice recording permissions denied - microphone: \(microphoneAuthorized, privacy: .public), speech: \(speechAuthorized, privacy: .public)")
        }

        return granted
    }

    func checkPermissions() -> Bool {
        if let microphonePermission = cachedMicrophonePermission,
           let speechPermission = cachedSpeechPermission
        {
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
        AppLogger.voice.info("Starting voice recording")

        // Reset state
        transcribedText = ""
        errorMessage = nil
        recordingDuration = 0

        // Check permissions
        let hasPermissions = await requestPermissions()
        guard hasPermissions else {
            AppLogger.voice.error("Recording failed - permissions denied")
            errorMessage = "Microphone and speech recognition permissions are required"
            throw RecordingError.permissionDenied
        }

        // Check speech recognizer availability
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            AppLogger.voice.error("Recording failed - speech recognizer not available")
            errorMessage = "Speech recognition is not available"
            throw RecordingError.recognizerNotAvailable
        }

        // Configure audio session
        AppLogger.voice.debug("Configuring audio session")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            AppLogger.voice.debug("Audio session configured successfully")
        } catch {
            AppLogger.voice.error("Audio session setup failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            AppLogger.voice.error("Failed to create recognition request")
            errorMessage = "Unable to create recognition request"
            throw RecordingError.failedToCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Offline-first
        AppLogger.voice.debug("Recognition request created - onDevice: true")

        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine else {
            AppLogger.voice.error("Failed to create audio engine")
            errorMessage = "Unable to create audio engine"
            throw RecordingError.failedToCreateAudioEngine
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            AppLogger.voice.debug("Audio engine started successfully")
        } catch {
            AppLogger.voice.error("Audio engine start failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Start recognition task
        isTranscribing = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result {
                transcribedText = result.bestTranscription.formattedString
            }

            if let error {
                AppLogger.voice.error("Recognition task error: \(error.localizedDescription, privacy: .public)")
                stopRecording()
            }
        }

        // Start recording timer
        isRecording = true
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }

        AppLogger.voice.info("Voice recording started - recognition task active")
    }

    func stopRecording() {
        let duration = recordingDuration
        let transcriptionLength = transcribedText.count
        AppLogger.voice.info("Stopping voice recording - duration: \(String(format: "%.1f", duration), privacy: .public)s, transcription length: \(transcriptionLength, privacy: .public)")

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

        AppLogger.voice.debug("Voice recording stopped and cleaned up")
    }

    func cancelRecording() {
        AppLogger.voice.info("Voice recording cancelled by user")
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
                "Microphone and speech recognition permissions are required"
            case .recognizerNotAvailable:
                "Speech recognition is not available on this device"
            case .failedToCreateRequest:
                "Failed to initialize speech recognition"
            case .failedToCreateAudioEngine:
                "Failed to initialize audio recording"
            case .recordingFailed:
                "Recording failed unexpectedly"
            }
        }
    }
}
