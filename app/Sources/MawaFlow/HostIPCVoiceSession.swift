import AVFoundation
import Combine
import Foundation

/// Background-capable recorder controlled by the keyboard extension through MawaIPC.
///
/// This is the Wispr/Dictus-style architecture: the keyboard remains the UX and
/// insertion surface, while the containing app owns the microphone/audio session.
final class HostIPCVoiceSession: ObservableObject {
    private var startObserver: MawaDarwinNotificationObserver?
    private var stopObserver: MawaDarwinNotificationObserver?
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var currentRequestID: String?
    private var currentMode: MawaMode = .dictate
    private var isObserving = false

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        startObserver = MawaDarwinNotificationObserver(name: MawaIPC.NotificationName.startRecording) { [weak self] in
            DispatchQueue.main.async { self?.handleStartCommand() }
        }
        stopObserver = MawaDarwinNotificationObserver(name: MawaIPC.NotificationName.stopRecording) { [weak self] in
            DispatchQueue.main.async { self?.handleStopCommand() }
        }
        MawaDiagnostics.send(event: "host_ipc_session_observing", source: "host", details: ["appGroup": MawaIPC.appGroupID])
    }

    private func handleStartCommand() {
        guard let defaults = MawaIPC.sharedDefaults else {
            MawaDiagnostics.send(event: "host_ipc_start_failed", source: "host", details: ["error": "app_group_defaults_unavailable"])
            return
        }
        let requestID = defaults.string(forKey: MawaIPC.Key.requestID) ?? UUID().uuidString
        let modeRaw = defaults.string(forKey: MawaIPC.Key.mode) ?? MawaMode.dictate.rawValue
        currentMode = MawaMode(rawValue: modeRaw) ?? .dictate
        currentRequestID = requestID
        MawaDiagnostics.send(event: "host_ipc_start_received", source: "host", details: ["requestID": requestID, "mode": currentMode.rawValue])
        startRecording(requestID: requestID)
    }

    private func startRecording(requestID: String) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard let self else { return }
                guard allowed else {
                    MawaIPC.writeState(MawaIPC.State.failed, requestID: requestID, error: "Microphone permission denied in host app")
                    MawaIPC.post(MawaIPC.NotificationName.resultReady)
                    MawaDiagnostics.send(event: "host_ipc_permission_denied", source: "host", details: ["requestID": requestID])
                    return
                }
                do {
                    self.recorder?.stop()
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
                    try session.setPreferredSampleRate(16_000)
                    try session.setPreferredInputNumberOfChannels(1)
                    try session.setActive(true, options: [])

                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("mawa-ipc-host-\(requestID).m4a")
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 16_000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    let recorder = try AVAudioRecorder(url: url, settings: settings)
                    recorder.isMeteringEnabled = true
                    recorder.prepareToRecord()
                    guard recorder.record() else {
                        throw NSError(domain: "MawaHostIPC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Host AVAudioRecorder returned false"])
                    }

                    self.recordingURL = url
                    self.recorder = recorder
                    MawaIPC.writeState(MawaIPC.State.recording, requestID: requestID)
                    MawaDiagnostics.send(event: "host_ipc_recording_started", source: "host", details: ["requestID": requestID, "mode": self.currentMode.rawValue])
                } catch {
                    MawaIPC.writeState(MawaIPC.State.failed, requestID: requestID, error: error.localizedDescription)
                    MawaIPC.post(MawaIPC.NotificationName.resultReady)
                    MawaDiagnostics.send(event: "host_ipc_recording_failed", source: "host", details: ["requestID": requestID, "error": error.localizedDescription])
                }
            }
        }
    }

    private func handleStopCommand() {
        guard let requestID = currentRequestID ?? MawaIPC.sharedDefaults?.string(forKey: MawaIPC.Key.requestID) else {
            MawaDiagnostics.send(event: "host_ipc_stop_ignored", source: "host", details: ["error": "missing_request_id"])
            return
        }
        MawaDiagnostics.send(event: "host_ipc_stop_received", source: "host", details: ["requestID": requestID, "mode": currentMode.rawValue])
        stopRecordingAndTranscribe(requestID: requestID)
    }

    private func stopRecordingAndTranscribe(requestID: String) {
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        MawaIPC.writeState(MawaIPC.State.processing, requestID: requestID)

        guard let recordingURL else {
            MawaIPC.writeState(MawaIPC.State.failed, requestID: requestID, error: "No host recording found")
            MawaIPC.post(MawaIPC.NotificationName.resultReady)
            return
        }

        MawaDiagnostics.send(event: "host_ipc_recording_finished", source: "host", details: ["requestID": requestID, "mode": currentMode.rawValue])
        MawaDiagnostics.transcribeAudio(fileURL: recordingURL, mode: currentMode.rawValue) { [weak self] result in
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: recordingURL)
                self?.recordingURL = nil
                switch result {
                case .success(let transcript):
                    let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    MawaIPC.writeState(MawaIPC.State.ready, requestID: requestID, transcript: cleaned)
                    MawaIPC.post(MawaIPC.NotificationName.resultReady)
                    MawaDiagnostics.send(event: "host_ipc_transcription_success", source: "host", details: ["requestID": requestID, "chars": String(cleaned.count), "mode": self?.currentMode.rawValue ?? "unknown"])
                case .failure(let error):
                    MawaIPC.writeState(MawaIPC.State.failed, requestID: requestID, error: error.localizedDescription)
                    MawaIPC.post(MawaIPC.NotificationName.resultReady)
                    MawaDiagnostics.send(event: "host_ipc_transcription_failed", source: "host", details: ["requestID": requestID, "error": error.localizedDescription])
                }
            }
        }
    }
}
