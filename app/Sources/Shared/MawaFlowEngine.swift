import Foundation

public enum MawaMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case dictate = "Dictate"
    case reply = "Reply"
    case prompt = "Prompt"
    case rewrite = "Rewrite"
    case ask = "Ask"

    public var id: String { rawValue }

    public var shortLabel: String {
        switch self {
        case .auto: return "Auto"
        case .dictate: return "Dictate"
        case .reply: return "Reply"
        case .prompt: return "Prompt"
        case .rewrite: return "Rewrite"
        case .ask: return "Ask"
        }
    }

    public var icon: String {
        switch self {
        case .auto: return "sparkles"
        case .dictate: return "text.quote"
        case .reply: return "bubble.left.and.bubble.right"
        case .prompt: return "wand.and.stars"
        case .rewrite: return "pencil.and.outline"
        case .ask: return "questionmark.circle"
        }
    }
}

public struct MawaGenerationResult: Equatable {
    public let mode: MawaMode
    public let intentLabel: String
    public let output: String
    public let privacyLabel: String
    public let contextLabel: String

    public init(mode: MawaMode, intentLabel: String, output: String, privacyLabel: String = "Local demo", contextLabel: String = "No external context") {
        self.mode = mode
        self.intentLabel = intentLabel
        self.output = output
        self.privacyLabel = privacyLabel
        self.contextLabel = contextLabel
    }
}

public enum MawaFlowEngine {
    public static let defaultDraft = "reply saying I checked it and it is probably missing an API key but make it professional"

    public static let demoSamples: [(title: String, text: String, mode: MawaMode)] = [
        ("API reply", "reply saying I checked it and it is probably missing an API key but make it professional", .reply),
        ("Cursor prompt", "make a prompt for Cursor to build a mobile first landing page for a voice keyboard app", .prompt),
        ("Clean update", "um tell the team I am checking the bug and I will send an update tonight", .dictate),
        ("Rewrite", "rewrite this to sound warmer: I need this done today or the project will slip", .rewrite)
    ]

    public static func resolveMode(_ requestedMode: MawaMode, draft: String) -> MawaMode {
        guard requestedMode == .auto else { return requestedMode }
        let lower = draft.lowercased()
        if lower.contains("prompt") || lower.contains("cursor") || lower.contains("chatgpt") { return .prompt }
        if lower.contains("reply") || lower.contains("tell ") || lower.contains("say ") { return .reply }
        if lower.contains("rewrite") || lower.contains("make this") { return .rewrite }
        if lower.hasSuffix("?") || lower.hasPrefix("what") || lower.hasPrefix("how") { return .ask }
        return .dictate
    }

    public static func generate(draft: String, requestedMode: MawaMode, variant: Int = 0) -> MawaGenerationResult {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = trimmed.isEmpty ? defaultDraft : trimmed
        let mode = resolveMode(requestedMode, draft: input)
        let output: String
        let intent: String

        switch mode {
        case .auto:
            // resolveMode prevents this in normal use, but keep a safe fallback.
            intent = "Auto"
            output = cleanDictation(input)
        case .dictate:
            intent = "Clean dictation"
            output = cleanDictation(input)
        case .reply:
            intent = "Message reply"
            output = replyText(input, variant: variant)
        case .prompt:
            intent = "Prompt builder"
            output = promptText(input, variant: variant)
        case .rewrite:
            intent = "Rewrite"
            output = rewriteText(input, variant: variant)
        case .ask:
            intent = "Answer draft"
            output = askText(input)
        }

        return MawaGenerationResult(mode: mode, intentLabel: intent, output: output)
    }

    public static func shorter(_ text: String) -> String {
        let sentences = text.split(separator: ".", omittingEmptySubsequences: true).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        if let first = sentences.first, !first.isEmpty { return first + "." }
        return text.count > 90 ? String(text.prefix(87)) + "..." : text
    }

    public static func warmer(_ text: String) -> String {
        if text.lowercased().hasPrefix("hey") { return text }
        return "Hey — " + text.prefix(1).lowercased() + String(text.dropFirst())
    }

    private static func cleanDictation(_ input: String) -> String {
        var text = input
            .replacingOccurrences(of: "um ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "uh ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "like ", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        text = capitalizeFirst(text)
        if !text.hasSuffix(".") && !text.hasSuffix("!") && !text.hasSuffix("?") { text += "." }
        return text
    }

    private static func replyText(_ input: String, variant: Int) -> String {
        if input.lowercased().contains("api key") {
            return variant % 2 == 0
                ? "I checked this, and it looks like the issue may be related to a missing API key. I’ll verify the configuration and follow up with next steps."
                : "I took a look, and the most likely cause is a missing API key. I’ll confirm the setup and send an update once I’ve verified it."
        }
        return "Thanks for the context. I’ll take a look and follow up with a clear update shortly."
    }

    private static func promptText(_ input: String, variant: Int) -> String {
        if input.lowercased().contains("landing page") {
            return "Build a mobile-first landing page for an AI voice keyboard app. Use a clean, premium iOS-inspired design with a warm brand voice. Include a hero, before/after demo, feature cards, privacy section, pricing preview, and a strong call to action. Optimize the layout for iPhone screens first."
        }
        return "Turn this idea into a clear implementation plan. Explain the goal, user flow, required screens, data model, edge cases, and acceptance criteria. Keep the first version simple and demo-ready."
    }

    private static func rewriteText(_ input: String, variant: Int) -> String {
        if input.lowercased().contains("done today") {
            return "Could you please prioritize this today? If it slips, it may affect the project timeline, so I’d really appreciate an update when you can."
        }
        return cleanDictation(input.replacingOccurrences(of: "rewrite this to sound warmer:", with: "", options: .caseInsensitive))
    }

    private static func askText(_ input: String) -> String {
        return "Here’s the short answer: start with the simplest version that proves the core workflow, then layer in context and automation once the keyboard insertion flow is reliable."
    }

    private static func capitalizeFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + String(text.dropFirst())
    }
}
