import AVFoundation
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SetupView()
                .tabItem { Label("Setup", systemImage: "checklist") }
            DemoLabView()
                .tabItem { Label("Demo", systemImage: "waveform") }
            DiagnosticsView()
                .tabItem { Label("Diagnostics", systemImage: "stethoscope") }
            PrivacyView()
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
        }
        .tint(.mawaTeal)
        .onAppear {
            MawaDiagnostics.send(event: "host_app_opened", source: "host")
        }
    }
}

private struct SetupView: View {
    @AppStorage("mawaProvider") private var provider = "Mawa Cloud"
    @AppStorage("mawaBYOKey") private var byoKey = ""
    @AppStorage("mawaLocalMode") private var localMode = false
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
                        setupEvent = "Setup saved. Now switch to the keyboard in Notes."
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
