import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
    private enum AppTab: Hashable {
        case setup
        case voiceTest
        case demo
        case diagnostics
        case privacy
    }

    @AppStorage("mawaSetupComplete") private var setupComplete = false
    @State private var selectedTab: AppTab = .setup
    @StateObject private var ipcVoiceSession = HostIPCVoiceSession()

    var body: some View {
        Group {
            if setupComplete {
                mainTabs
            } else {
                SetupView()
            }
        }
        .tint(.mawaTeal)
        .onAppear {
            MawaDiagnostics.send(event: "host_app_opened", source: "host")
            ipcVoiceSession.startObserving()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            SetupView()
                .tabItem { Label("Setup", systemImage: "checklist") }
                .tag(AppTab.setup)
            HostVoiceTestView()
                .tabItem { Label("Voice Test", systemImage: "mic.circle") }
                .tag(AppTab.voiceTest)
            DemoLabView()
                .tabItem { Label("Demo", systemImage: "waveform") }
                .tag(AppTab.demo)
            DiagnosticsView()
                .tabItem { Label("Diagnostics", systemImage: "stethoscope") }
                .tag(AppTab.diagnostics)
            PrivacyView()
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
                .tag(AppTab.privacy)
        }
    }

    private func handleDeepLink(_ url: URL) {
        MawaDiagnostics.send(event: "host_deep_link_opened", source: "host", details: ["url": url.absoluteString])
        guard url.scheme == "mawaflow" else { return }
        if url.host == "voice-test" || url.path.contains("voice-test") {
            setupComplete = true
            selectedTab = .voiceTest
        }
    }
}

private struct SetupView: View {
    @AppStorage("mawaProvider") private var provider = "Mawa Cloud"
    @AppStorage("mawaBYOKey") private var byoKey = ""
    @AppStorage("mawaLocalMode") private var localMode = false
    @AppStorage("mawaSetupComplete") private var setupComplete = false
    @State private var micStatus = "Not checked"
    @State private var setupEvent = ""

    private let providers = ["Mawa Cloud", "Bring Your Own Key", "Local / On-device", "Custom Endpoint"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeroCard()

                    SectionCard(title: "1. Microphone permission", icon: "mic.fill") {
                        Text("Do this before using the keyboard. iOS may not show the mic permission prompt from inside a keyboard extension, so Mawa asks here first.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            StatusBadge(text: micStatus, color: micStatus == "Allowed" ? .green : .orange)
                            Spacer()
                            Button("Request Mic") { requestMicrophone() }
                                .buttonStyle(.borderedProminent)
                                .tint(.mawaTeal)
                        }
                    }

                    SectionCard(title: "2. Choose voice/AI provider", icon: "server.rack") {
                        Picker("Provider", selection: $provider) {
                            ForEach(providers, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: provider) { newValue in
                            MawaDiagnostics.send(event: "host_provider_selected", source: "host", details: ["provider": newValue])
                        }

                        Toggle("Prefer local/on-device processing when available", isOn: $localMode)
                            .tint(.mawaTeal)

                        if provider == "Bring Your Own Key" {
                            SecureField("Paste API key here", text: $byoKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                            Text("Prototype note: this saves locally for now. Production should move BYO keys to Keychain/App Group and never put provider keys in the IPA.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if provider == "Local / On-device" {
                            Text("Local mode will use on-device speech/Whisper later. This avoids per-request cloud cost but needs a larger model download.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if provider == "Custom Endpoint" {
                            Text("Custom endpoint support is planned so advanced users can bring their own server.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Mawa Cloud uses the Mawa VPS proxy. Provider keys stay server-side, not inside the app.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    SectionCard(title: "3. Enable keyboard + Full Access", icon: "keyboard") {
                        SetupStep(number: "A", text: "Settings → General → Keyboard → Keyboards → Add New Keyboard → Mawa Flow Keyboard")
                        SetupStep(number: "B", text: "Open Mawa Flow Keyboard settings and turn on Allow Full Access for voice/AI network features")
                        SetupStep(number: "C", text: "Open Notes, tap the text box, globe → Mawa Flow Keyboard")
                    }

                    Button {
                        MawaDiagnostics.send(
                            event: "host_setup_completed_tapped",
                            source: "host",
                            details: ["provider": provider, "localMode": String(localMode), "hasBYOKey": String(!byoKey.isEmpty)]
                        )
                        setupComplete = true
                        setupEvent = "Setup saved. Now test voice recording or switch to the keyboard in Notes."
                    } label: {
                        Label("I’m Ready to Use Mawa Keyboard", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mawaTeal)

                    if !setupEvent.isEmpty {
                        Text(setupEvent)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.mawaTeal)
                    }
                }
                .padding(20)
            }
            .background(Color.mawaIvory.ignoresSafeArea())
            .navigationTitle("Mawa Setup")
            .onAppear { refreshMicStatus() }
        }
    }

    private func refreshMicStatus() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            micStatus = "Allowed"
        case .denied:
            micStatus = "Denied"
        case .undetermined:
            micStatus = "Not asked yet"
        @unknown default:
            micStatus = "Unknown"
        }
    }

    private func requestMicrophone() {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                micStatus = allowed ? "Allowed" : "Denied"
                MawaDiagnostics.send(event: "host_mic_permission_result", source: "host", details: ["allowed": String(allowed)])
            }
        }
    }
}

private struct HeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Mawa Voice Keyboard", systemImage: "waveform")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.mawaTeal)
            Text("Speak messy.\nMawa writes clearly.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineSpacing(1)
            Text("Set up permissions, provider choice, and keyboard access before using voice dictation.")
                .font(.body)
                .foregroundStyle(.secondary)
            HStack {
                Pill(text: "Dictate")
                Pill(text: "Reply")
                Pill(text: "Rewrite")
                Pill(text: "Prompt")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.black.opacity(0.06)))
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Color.mawaTeal)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.black.opacity(0.05)))
    }
}

private struct SetupStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.mawaTeal, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
            .foregroundStyle(color)
    }
}

private final class HostVoiceRecorder: NSObject, ObservableObject {
    @Published var state = "Ready"
    @Published var transcript = ""
    @Published var output = ""
    @Published var isRecording = false
    @Published var selectedMode: MawaMode = .dictate

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func toggleRecording() {
        isRecording ? stop() : start()
    }

    private func start() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard let self else { return }
                guard allowed else {
                    self.state = "Mic permission denied"
                    MawaDiagnostics.send(event: "host_voice_test_permission_denied", source: "host")
                    return
                }
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .duckOthers])
                    try session.setActive(true)
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("mawa-host-voice-\(UUID().uuidString).m4a")
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 16_000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    let recorder = try AVAudioRecorder(url: url, settings: settings)
                    recorder.prepareToRecord()
                    if recorder.record() {
                        self.recordingURL = url
                        self.recorder = recorder
                        self.isRecording = true
                        self.state = "Recording… tap stop when done"
                        self.transcript = ""
                        self.output = ""
                        MawaDiagnostics.send(event: "host_voice_test_recording_started", source: "host", details: ["mode": self.selectedMode.rawValue])
                    } else {
                        self.state = "Recorder did not start"
                        MawaDiagnostics.send(event: "host_voice_test_recording_failed", source: "host", details: ["error": "record_returned_false"])
                    }
                } catch {
                    self.state = "Recording failed: \(error.localizedDescription)"
                    MawaDiagnostics.send(event: "host_voice_test_recording_failed", source: "host", details: ["error": error.localizedDescription])
                }
            }
        }
    }

    private func stop() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        state = "Transcribing…"
        MawaDiagnostics.send(event: "host_voice_test_recording_finished", source: "host", details: ["mode": selectedMode.rawValue])

        guard let recordingURL else {
            state = "No recording found"
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
                    self.transcript = cleaned.isEmpty ? "No speech detected" : cleaned
                    if cleaned.isEmpty {
                        self.output = "Try again closer to the microphone."
                    } else {
                        self.output = MawaFlowEngine.generate(draft: cleaned, requestedMode: self.selectedMode).output
                        UIPasteboard.general.string = self.output
                    }
                    self.state = cleaned.isEmpty ? "Done" : "Done — output copied"
                    MawaDiagnostics.send(event: "host_voice_test_transcription_success", source: "host", details: ["chars": String(cleaned.count), "mode": self.selectedMode.rawValue, "copied": String(!cleaned.isEmpty)])
                case .failure(let error):
                    self.state = "Transcription failed"
                    self.output = error.localizedDescription
                    MawaDiagnostics.send(event: "host_voice_test_transcription_failed", source: "host", details: ["error": error.localizedDescription])
                }
            }
        }
    }
}

private struct HostVoiceTestView: View {
    @StateObject private var recorder = HostVoiceRecorder()
    private let modes: [MawaMode] = [.dictate, .reply, .rewrite, .prompt]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard(title: "Voice recording test", icon: "mic.circle.fill") {
                        Text("This records from the main app, not the keyboard extension. Direct keyboard mic capture is blocked on this device, so this is the reliable handoff path: record here, Mawa auto-copies the output, then return to the original app and tap Insert on the Mawa keyboard.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Mode", selection: $recorder.selectedMode) {
                            ForEach(modes) { mode in Text(mode.rawValue).tag(mode) }
                        }
                        .pickerStyle(.segmented)
                        Button {
                            recorder.toggleRecording()
                        } label: {
                            Label(recorder.isRecording ? "Stop + Transcribe" : "Start Recording", systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(recorder.isRecording ? .red : .mawaTeal)
                        StatusBadge(text: recorder.state, color: recorder.isRecording ? .red : .mawaTeal)
                    }

                    SectionCard(title: "Transcript", icon: "text.quote") {
                        Text(recorder.transcript.isEmpty ? "No transcript yet." : recorder.transcript)
                            .font(.body)
                            .textSelection(.enabled)
                    }

                    SectionCard(title: "Mawa output", icon: "sparkles") {
                        Text(recorder.output.isEmpty ? "No output yet." : recorder.output)
                            .font(.body)
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = recorder.output
                            MawaDiagnostics.send(event: "host_voice_test_copied_output", source: "host")
                        } label: {
                            Label("Copy Output", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(recorder.output.isEmpty)
                    }
                }
                .padding(20)
            }
            .background(Color.mawaIvory.ignoresSafeArea())
            .navigationTitle("Voice Test")
        }
    }
}

private struct DemoLabView: View {
    @State private var selectedMode: MawaMode = .auto
    @State private var draft: String = MawaFlowEngine.defaultDraft
    @State private var result = MawaFlowEngine.generate(draft: MawaFlowEngine.defaultDraft, requestedMode: .auto)
    @State private var variant = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Try the local demo brain before using the keyboard extension.")
                        .foregroundStyle(.secondary)
                    modePicker
                    TextEditor(text: $draft)
                        .font(.body)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    Button {
                        result = MawaFlowEngine.generate(draft: draft, requestedMode: selectedMode, variant: variant)
                        variant += 1
                    } label: {
                        Label("Generate Preview", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mawaTeal)

                    ResultCard(result: result)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sample prompts").font(.headline)
                        ForEach(Array(MawaFlowEngine.demoSamples.enumerated()), id: \.offset) { _, sample in
                            Button {
                                selectedMode = sample.mode
                                draft = sample.text
                                result = MawaFlowEngine.generate(draft: sample.text, requestedMode: sample.mode)
                            } label: {
                                HStack {
                                    Text(sample.title)
                                    Spacer()
                                    Text(sample.mode.rawValue).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.mawaIvory.ignoresSafeArea())
            .navigationTitle("Demo Lab")
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach([MawaMode.auto, .dictate, .reply, .prompt, .rewrite, .ask]) { mode in
                    Button(mode.shortLabel) { selectedMode = mode }
                        .buttonStyle(.bordered)
                        .tint(selectedMode == mode ? .mawaTeal : .secondary)
                }
            }
        }
    }
}

private struct DiagnosticsView: View {
    @State private var status = "No diagnostic event sent yet."

    var body: some View {
        NavigationStack {
            List {
                Section("Live diagnostics") {
                    Text("Use this while we debug setup, keyboard switching, mic permission, and transcription. It does not send typed text or clipboard content.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        MawaDiagnostics.send(
                            event: "host_manual_test_button",
                            source: "host",
                            details: ["screen": "Diagnostics"]
                        )
                        status = "Sent test event. Tell Mawa you tapped it."
                    } label: {
                        Label("Send Test Event", systemImage: "paperplane")
                    }
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("If mic does not ask") {
                    Text("Use Setup → Request Mic first. iOS may not show permission prompts from the keyboard extension.")
                    Text("If permission is Allowed but recording still fails, send logs — iOS may block direct recording from keyboard extensions and we’ll use a host-app handoff.")
                }
            }
            .navigationTitle("Diagnostics")
        }
    }
}

private struct PrivacyView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("What Mawa needs") {
                    Label("Microphone only when you tap the mic", systemImage: "mic")
                    Label("Full Access for cloud/BYO/server STT", systemImage: "network")
                    Label("Keyboard access to insert final text", systemImage: "keyboard")
                }
                Section("Provider choices") {
                    Label("Mawa Cloud / VPS proxy", systemImage: "cloud")
                    Label("Bring Your Own API key", systemImage: "key")
                    Label("Local/on-device planned", systemImage: "iphone")
                    Label("Custom endpoint planned", systemImage: "server.rack")
                }
                Section("Safety") {
                    Text("Provider keys should not be shipped inside the IPA. Production BYO keys should use Keychain/App Group storage. Audio is only sent when the user explicitly taps mic and stops recording.")
                        .font(.subheadline)
                }
            }
            .navigationTitle("Privacy")
        }
    }
}

private struct ResultCard: View {
    let result: MawaGenerationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(result.intentLabel, systemImage: result.mode.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.mawaTeal)
                Spacer()
                Text(result.privacyLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.mawaViolet.opacity(0.22), in: Capsule())
            }
            Text(result.output)
                .font(.body)
                .textSelection(.enabled)
            Text("Context: \(result.contextLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct Pill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.mawaViolet.opacity(0.22), in: Capsule())
    }
}

extension Color {
    static let mawaIvory = Color(red: 0.98, green: 0.97, blue: 0.93)
    static let mawaTeal = Color(red: 0.02, green: 0.42, blue: 0.35)
    static let mawaViolet = Color(red: 0.73, green: 0.58, blue: 1.0)
}
