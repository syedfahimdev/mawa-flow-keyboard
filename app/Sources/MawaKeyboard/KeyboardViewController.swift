import AVFoundation
import UIKit

private final class WaveBarView: UIView {
    private let bars: [UIView]

    override init(frame: CGRect) {
        bars = (0..<9).map { _ in UIView() }
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        bars = (0..<9).map { _ in UIView() }
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let stack = UIStackView(arrangedSubviews: bars)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = UIColor.white.withAlphaComponent(0.95)
            bar.layer.cornerRadius = 3
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.widthAnchor.constraint(equalToConstant: 6).isActive = true
            bar.heightAnchor.constraint(equalToConstant: CGFloat([16, 28, 42, 58, 74, 58, 42, 28, 16][index])).isActive = true
        }
    }

    func start() {
        stop()
        for (index, bar) in bars.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = 0.35
            animation.toValue = 1.15
            animation.duration = 0.44
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.055
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.layer.add(animation, forKey: "mawa.wave")
        }
    }

    func stop() {
        bars.forEach { $0.layer.removeAnimation(forKey: "mawa.wave") }
    }
}

final class KeyboardViewController: UIInputViewController {
    private enum VoiceState {
        case idle
        case listening
        case processing
        case ready
    }

    private var voiceState: VoiceState = .idle
    private var selectedMode: MawaMode = .dictate
    private var variant = 0
    private var generatedText = ""
    private var currentTranscript = ""
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var recordingBackend = "none"

    private let rootStack = UIStackView()
    private let modeStack = UIStackView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let transcriptLabel = UILabel()
    private let previewLabel = UILabel()
    private let micButton = UIButton(type: .system)
    private let waveView = WaveBarView()

    private let background = UIColor(red: 0.04, green: 0.06, blue: 0.09, alpha: 1.0)
    private let card = UIColor(red: 0.10, green: 0.12, blue: 0.17, alpha: 1.0)
    private let cardLight = UIColor(red: 0.15, green: 0.17, blue: 0.23, alpha: 1.0)
    private let blue = UIColor(red: 0.04, green: 0.52, blue: 0.96, alpha: 1.0)
    private let violet = UIColor(red: 0.56, green: 0.42, blue: 1.0, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        MawaDiagnostics.send(
            event: "keyboard_view_did_load",
            source: "keyboard",
            details: [
                "has_full_access": String(hasFullAccess),
                "needs_input_mode_switch_key": String(needsInputModeSwitchKey),
                "layout": "voice_mic_wave_v1"
            ]
        )
        setupVoiceKeyboard()
        updateState(.idle)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MawaDiagnostics.send(
            event: "keyboard_view_did_appear",
            source: "keyboard",
            details: ["has_full_access": String(hasFullAccess)]
        )
    }

    private func setupVoiceKeyboard() {
        view.backgroundColor = background
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 332).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 10
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        rootStack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let header = UIStackView()
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center

        let globe = roundIconButton("🌐", action: #selector(handleNextKeyboard))
        globe.widthAnchor.constraint(equalToConstant: 38).isActive = true
        header.addArrangedSubview(globe)

        let titleBlock = UIStackView()
        titleBlock.axis = .vertical
        titleBlock.spacing = 1

        titleLabel.text = "Mawa Voice"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleBlock.addArrangedSubview(titleLabel)

        statusLabel.text = "Tap mic to start dictation"
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        titleBlock.addArrangedSubview(statusLabel)

        header.addArrangedSubview(titleBlock)

        let clear = pillButton("Clear", action: #selector(handleClear), filled: false)
        clear.widthAnchor.constraint(equalToConstant: 66).isActive = true
        header.addArrangedSubview(clear)

        rootStack.addArrangedSubview(header)

        modeStack.axis = .horizontal
        modeStack.spacing = 7
        modeStack.distribution = .fillEqually
        rootStack.addArrangedSubview(modeStack)
        rebuildModeButtons()

        let voiceCard = UIView()
        voiceCard.backgroundColor = card
        voiceCard.layer.cornerRadius = 28
        voiceCard.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(voiceCard)

        let voiceStack = UIStackView()
        voiceStack.axis = .vertical
        voiceStack.alignment = .center
        voiceStack.spacing = 12
        voiceStack.translatesAutoresizingMaskIntoConstraints = false
        voiceCard.addSubview(voiceStack)

        NSLayoutConstraint.activate([
            voiceStack.leadingAnchor.constraint(equalTo: voiceCard.leadingAnchor, constant: 16),
            voiceStack.trailingAnchor.constraint(equalTo: voiceCard.trailingAnchor, constant: -16),
            voiceStack.topAnchor.constraint(equalTo: voiceCard.topAnchor, constant: 14),
            voiceStack.bottomAnchor.constraint(equalTo: voiceCard.bottomAnchor, constant: -14),
            voiceCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 168)
        ])

        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveView.heightAnchor.constraint(equalToConstant: 78).isActive = true
        waveView.widthAnchor.constraint(equalToConstant: 118).isActive = true
        voiceStack.addArrangedSubview(waveView)

        micButton.setTitle("🎙", for: .normal)
        micButton.titleLabel?.font = .systemFont(ofSize: 42)
        micButton.backgroundColor = blue
        micButton.layer.cornerRadius = 36
        micButton.layer.shadowColor = blue.cgColor
        micButton.layer.shadowOpacity = 0.45
        micButton.layer.shadowRadius = 14
        micButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        micButton.widthAnchor.constraint(equalToConstant: 72).isActive = true
        micButton.heightAnchor.constraint(equalToConstant: 72).isActive = true
        micButton.addTarget(self, action: #selector(handleMicTapped), for: .touchUpInside)
        voiceStack.addArrangedSubview(micButton)

        transcriptLabel.textAlignment = .center
        transcriptLabel.numberOfLines = 2
        transcriptLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        transcriptLabel.textColor = UIColor.white.withAlphaComponent(0.90)
        voiceStack.addArrangedSubview(transcriptLabel)

        previewLabel.numberOfLines = 3
        previewLabel.font = .systemFont(ofSize: 14, weight: .regular)
        previewLabel.textColor = .white
        previewLabel.backgroundColor = cardLight
        previewLabel.layer.cornerRadius = 16
        previewLabel.layer.masksToBounds = true
        rootStack.addArrangedSubview(padded(previewLabel, inset: 12, background: cardLight, cornerRadius: 16, minHeight: 62))

        let actionRow = UIStackView()
        actionRow.axis = .horizontal
        actionRow.spacing = 8
        actionRow.distribution = .fillEqually
        actionRow.addArrangedSubview(pillButton("Regenerate", action: #selector(handleRegenerate), filled: false))
        actionRow.addArrangedSubview(pillButton("Open App", action: #selector(handleOpenApp), filled: false))
        actionRow.addArrangedSubview(pillButton("Insert", action: #selector(handleInsert), filled: true))
        rootStack.addArrangedSubview(actionRow)
    }

    private func rebuildModeButtons() {
        modeStack.arrangedSubviews.forEach { view in
            modeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for mode in [MawaMode.dictate, .reply, .rewrite, .prompt] {
            let button = UIButton(type: .system)
            button.setTitle(mode.shortLabel, for: .normal)
            button.setTitleColor(mode == selectedMode ? .white : UIColor.white.withAlphaComponent(0.72), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.backgroundColor = mode == selectedMode ? violet : cardLight
            button.layer.cornerRadius = 14
            button.tag = [MawaMode.dictate, .reply, .rewrite, .prompt].firstIndex(of: mode) ?? 0
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
            button.addTarget(self, action: #selector(handleMode(_:)), for: .touchUpInside)
            modeStack.addArrangedSubview(button)
        }
    }

    private func roundIconButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = cardLight
        button.layer.cornerRadius = 16
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func pillButton(_ title: String, action: Selector, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(filled ? .white : UIColor.white.withAlphaComponent(0.86), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = filled ? blue : cardLight
        button.layer.cornerRadius = 17
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func padded(_ label: UILabel, inset: CGFloat, background: UIColor, cornerRadius: CGFloat, minHeight: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = background
        container.layer.cornerRadius = cornerRadius
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight)
        ])
        return container
    }

    private func updateState(_ state: VoiceState) {
        voiceState = state
        switch state {
        case .idle:
            waveView.stop()
            micButton.layer.removeAllAnimations()
            statusLabel.text = "Tap mic to start dictation"
            transcriptLabel.text = "Ready when you are"
            previewLabel.text = "Speak naturally. Mawa will record, transcribe, clean it up, then insert it here."
            micButton.backgroundColor = blue
            micButton.transform = .identity
        case .listening:
            waveView.start()
            statusLabel.text = "Listening… tap again to finish"
            transcriptLabel.text = "Recording from microphone…"
            previewLabel.text = "Speak your thought. Mawa will send this short audio clip to the VPS for Deepgram transcription."
            micButton.backgroundColor = violet
            UIView.animate(withDuration: 0.28, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
                self.micButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }
        case .processing:
            waveView.start()
            micButton.layer.removeAllAnimations()
            micButton.transform = .identity
            micButton.backgroundColor = violet
            statusLabel.text = "Transcribing…"
            transcriptLabel.text = "Processing your voice"
            previewLabel.text = "Sending audio to Mawa STT backend…"
        case .ready:
            waveView.stop()
            micButton.layer.removeAllAnimations()
            micButton.transform = .identity
            micButton.backgroundColor = blue
            statusLabel.text = "Draft ready"
            transcriptLabel.text = currentTranscript.isEmpty ? "Preview generated" : currentTranscript
            previewLabel.text = generatedText
        }
    }

    private func generateVoicePreview(from transcript: String? = nil) {
        let source = transcript?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? transcript! : sourceTextForPreview()
        currentTranscript = source
        let result = MawaFlowEngine.generate(draft: source, requestedMode: selectedMode, variant: variant)
        generatedText = result.output
        variant += 1
        MawaDiagnostics.send(event: "keyboard_voice_preview_generated", source: "keyboard", details: ["mode": selectedMode.rawValue])
    }

    private func sourceTextForPreview() -> String {
        if let before = textDocumentProxy.documentContextBeforeInput?.trimmingCharacters(in: .whitespacesAndNewlines), !before.isEmpty {
            return String(before.suffix(240))
        }
        switch selectedMode {
        case .dictate:
            return "um tell the team I am checking the bug and I will send an update tonight"
        case .reply:
            return "reply saying I checked it and it is probably missing an API key but make it professional"
        case .rewrite:
            return "rewrite this to sound warmer: I need this done today or the project will slip"
        case .prompt:
            return "make a prompt for Cursor to build a mobile first landing page for a voice keyboard app"
        default:
            return MawaFlowEngine.defaultDraft
        }
    }

    private func startRecording() {
        guard hasFullAccess else {
            MawaDiagnosticsSendMicError("full_access_disabled")
            statusLabel.text = "Full Access required"
            transcriptLabel.text = "Enable Full Access first"
            previewLabel.text = "Go to Settings → General → Keyboard → Keyboards → Mawa Flow Keyboard → Allow Full Access. Then reopen this keyboard."
            return
        }

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard let self else { return }
                guard allowed else {
                    self.MawaDiagnosticsSendMicError("permission_denied")
                    self.statusLabel.text = "Mic permission denied"
                    self.previewLabel.text = "Open the main Mawa app and allow microphone permission, then try again."
                    return
                }

                do {
                    try self.startAudioEngineRecording()
                    MawaDiagnostics.send(
                        event: "keyboard_recording_started",
                        source: "keyboard",
                        details: ["mode": self.selectedMode.rawValue, "backend": self.recordingBackend]
                    )
                    self.updateState(.listening)
                } catch {
                    MawaDiagnostics.send(
                        event: "keyboard_audio_engine_failed",
                        source: "keyboard",
                        details: ["mode": self.selectedMode.rawValue, "error": error.localizedDescription]
                    )
                    do {
                        try self.startAVRecorderFallback()
                        MawaDiagnostics.send(
                            event: "keyboard_recording_started",
                            source: "keyboard",
                            details: ["mode": self.selectedMode.rawValue, "backend": self.recordingBackend]
                        )
                        self.updateState(.listening)
                    } catch {
                        self.MawaDiagnosticsSendMicError(error.localizedDescription)
                        self.statusLabel.text = "Keyboard mic blocked"
                        self.transcriptLabel.text = "iOS did not start recording"
                        self.previewLabel.text = "I tried the Wispr-style live audio engine path and the recorder fallback, but iOS/signing still blocked microphone capture in the keyboard. Tap Open App for the reliable recorder while I inspect the new error logs."
                    }
                }
            }
        }
    }

    private func startAudioEngineRecording() throws {
        cleanupRecordingResources()
        var step = "session_category"
        do {
            let session = AVAudioSession.sharedInstance()
            // Open-source direct-keyboard attempts (Whispidik / WhisperSource) use
            // `.record` + `.measurement`. `.spokenAudio` produced OSStatus -50 in
            // our build 17 device logs at setCategory, so keep the category/mode
            // pair closest to those examples and let CAF handle the native format.
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            step = "preferred_sample_rate"
            try? session.setPreferredSampleRate(16_000)
            step = "preferred_channels"
            try? session.setPreferredInputNumberOfChannels(1)
            step = "session_active"
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            step = "engine_create"
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                throw NSError(domain: "MawaKeyboardRecording", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid input format: sampleRate=\(inputFormat.sampleRate), channels=\(inputFormat.channelCount)"])
            }

            // Use CAF with the device's native PCM format. The earlier WAV writer can fail
            // with CoreAudio 'what' when the input format cannot be represented as WAV.
            step = "open_caf_file"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("mawa-keyboard-engine-\(UUID().uuidString).caf")
            let file = try AVAudioFile(
                forWriting: url,
                settings: inputFormat.settings,
                commonFormat: inputFormat.commonFormat,
                interleaved: inputFormat.isInterleaved
            )

            step = "install_tap"
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                do {
                    try file.write(from: buffer)
                } catch {
                    self?.MawaDiagnosticsSendMicError("audio_file_write_failed: \(error.localizedDescription)")
                }
            }

            step = "engine_prepare"
            engine.prepare()
            step = "engine_start"
            try engine.start()
            guard engine.isRunning else {
                inputNode.removeTap(onBus: 0)
                throw NSError(domain: "MawaKeyboardRecording", code: -2, userInfo: [NSLocalizedDescriptionKey: "AVAudioEngine did not start"])
            }

            audioEngine = engine
            audioFile = file
            recordingURL = url
            recordingBackend = "audio_engine_caf"
        } catch {
            throw NSError(domain: "MawaKeyboardRecording", code: -5, userInfo: [NSLocalizedDescriptionKey: "\(step): \(error.localizedDescription)"])
        }
    }

    private func startAVRecorderFallback() throws {
        cleanupRecordingResources()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mawa-keyboard-recorder-\(UUID().uuidString).m4a")
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
            throw NSError(domain: "MawaKeyboardRecording", code: -3, userInfo: [NSLocalizedDescriptionKey: "AVAudioRecorder returned false"])
        }

        recordingURL = url
        audioRecorder = recorder
        recordingBackend = "av_audio_recorder_m4a"
    }

    private func stopRecordingAndTranscribe() {
        audioRecorder?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioRecorder = nil
        audioEngine = nil
        audioFile = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        MawaDiagnostics.send(
            event: "keyboard_recording_finished",
            source: "keyboard",
            details: ["mode": selectedMode.rawValue, "backend": recordingBackend]
        )
        updateState(.processing)

        guard let recordingURL else {
            generatedText = "No audio recording was found. Try again."
            updateState(.ready)
            return
        }

        MawaDiagnostics.transcribeAudio(fileURL: recordingURL, mode: selectedMode.rawValue) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                try? FileManager.default.removeItem(at: recordingURL)
                self.recordingURL = nil
                switch result {
                case .success(let transcript):
                    let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned.isEmpty {
                        self.currentTranscript = ""
                        self.generatedText = "I couldn’t detect speech. Try again a little closer to the mic."
                        MawaDiagnostics.send(event: "keyboard_transcription_empty", source: "keyboard", details: ["mode": self.selectedMode.rawValue])
                    } else {
                        self.generateVoicePreview(from: cleaned)
                        MawaDiagnostics.send(event: "keyboard_transcription_success", source: "keyboard", details: ["mode": self.selectedMode.rawValue, "chars": String(cleaned.count)])
                    }
                    self.updateState(.ready)
                case .failure(let error):
                    self.currentTranscript = ""
                    self.generatedText = "Transcription failed: \(error.localizedDescription)"
                    MawaDiagnostics.send(event: "keyboard_transcription_failed", source: "keyboard", details: ["mode": self.selectedMode.rawValue, "error": error.localizedDescription])
                    self.updateState(.ready)
                }
            }
        }
    }

    private func cleanupRecordingResources() {
        audioRecorder?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioRecorder = nil
        audioEngine = nil
        audioFile = nil
        recordingURL = nil
        recordingBackend = "none"
    }

    private func MawaDiagnosticsSendMicError(_ error: String) {
        MawaDiagnostics.send(event: "keyboard_recording_failed", source: "keyboard", details: ["mode": selectedMode.rawValue, "backend": recordingBackend, "error": error])
    }

    @objc private func handleMicTapped() {
        switch voiceState {
        case .idle, .ready:
            MawaDiagnostics.send(event: "keyboard_mic_started", source: "keyboard", details: ["mode": selectedMode.rawValue])
            startRecording()
        case .listening:
            MawaDiagnostics.send(event: "keyboard_mic_finished", source: "keyboard", details: ["mode": selectedMode.rawValue])
            stopRecordingAndTranscribe()
        case .processing:
            break
        }
    }

    @objc private func handleMode(_ sender: UIButton) {
        let allModes: [MawaMode] = [.dictate, .reply, .rewrite, .prompt]
        selectedMode = allModes[sender.tag]
        rebuildModeButtons()
        if voiceState == .ready {
            generateVoicePreview()
            updateState(.ready)
        }
    }

    @objc private func handleInsert() {
        let clipboardText = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if generatedText.isEmpty && !clipboardText.isEmpty {
            generatedText = clipboardText
            currentTranscript = "Copied from Mawa app"
            MawaDiagnostics.send(event: "keyboard_clipboard_output_loaded", source: "keyboard", details: ["chars": String(clipboardText.count)])
        }
        if generatedText.isEmpty { generateVoicePreview() }
        MawaDiagnostics.send(event: "keyboard_voice_insert_tapped", source: "keyboard", details: ["mode": selectedMode.rawValue, "chars": String(generatedText.count)])
        textDocumentProxy.insertText(generatedText)
        updateState(.idle)
    }

    @objc private func handleRegenerate() {
        generateVoicePreview()
        updateState(.ready)
    }

    @objc private func handleClear() {
        generatedText = ""
        updateState(.idle)
    }

    @objc private func handleOpenApp() {
        MawaDiagnostics.send(event: "keyboard_open_app_tapped", source: "keyboard")
        guard let url = URL(string: "mawaflow://voice-test") else { return }
        extensionContext?.open(url)
    }

    @objc private func handleNextKeyboard() {
        advanceToNextInputMode()
    }
}
