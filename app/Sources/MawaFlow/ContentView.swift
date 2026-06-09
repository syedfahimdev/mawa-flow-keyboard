import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OnboardingView()
                .tabItem { Label("Start", systemImage: "sparkles") }
            DemoLabView()
                .tabItem { Label("Demo", systemImage: "keyboard") }
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

private struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeroCard()
                    StepCard(number: "1", title: "Enable the keyboard", body: "Open Settings → General → Keyboard → Keyboards → Add New Keyboard → Mawa Flow.")
                    StepCard(number: "2", title: "Switch to Mawa", body: "In any normal text field, tap the globe key and choose Mawa Flow Keyboard.")
                    StepCard(number: "3", title: "Preview, then insert", body: "Phase 1 uses local demo templates. Tap Mawa, review the result, then insert into the active text box.")
                    Text("Phase 1 intentionally avoids cloud AI, real voice, and screen reading. Those come after the keyboard insertion flow is proven.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color.mawaIvory.ignoresSafeArea())
            .navigationTitle("Mawa Flow")
        }
    }
}

private struct HeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Mawa Flow Keyboard", systemImage: "waveform")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.mawaTeal)
            Text("Speak messy.\nMawa writes clearly.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineSpacing(1)
            Text("A warm, privacy-aware AI keyboard for turning rough thoughts into ready-to-send text.")
                .font(.body)
                .foregroundStyle(.secondary)
            HStack {
                Pill(text: "Auto")
                Pill(text: "Reply")
                Pill(text: "Prompt")
                Pill(text: "Rewrite")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.black.opacity(0.06)))
    }
}

private struct StepCard: View {
    let number: String
    let title: String
    let bodyText: String

    init(number: String, title: String, body: String) {
        self.number = number
        self.title = title
        self.bodyText = body
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.mawaTeal, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(bodyText).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                    Text("Try the local Phase 1 brain before using the keyboard extension.")
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
                    Text("Use this while we debug keyboard switching. It only sends lifecycle/status events — not your typed text, clipboard, messages, or screen content.")
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

                Section("Keyboard test steps") {
                    Text("1. Settings → General → Keyboard → Keyboards → Mawa Flow Keyboard.")
                    Text("2. Turn on Allow Full Access for this diagnostic build.")
                    Text("3. Open Notes and switch to Mawa from the globe menu.")
                    Text("4. If it bounces back, tell Mawa the exact time you tried.")
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
                Section("Phase 1") {
                    Label("No cloud calls", systemImage: "wifi.slash")
                    Label("No screen reading", systemImage: "eye.slash")
                    Label("Local deterministic demo templates", systemImage: "checkmark.shield")
                }
                Section("Later") {
                    Label("Real voice transcription", systemImage: "mic")
                    Label("Explicit context sources", systemImage: "doc.text.magnifyingglass")
                    Label("Permissioned skills and connectors", systemImage: "puzzlepiece.extension")
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
