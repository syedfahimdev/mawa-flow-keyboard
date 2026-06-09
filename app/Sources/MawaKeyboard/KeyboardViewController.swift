import UIKit

private final class MawaKeyButton: UIButton {
    var keyValue: String = ""
    var specialAction: String = ""
}

final class KeyboardViewController: UIInputViewController {
    private enum KeyboardPage {
        case letters
        case numbers
    }

    private let rootStack = UIStackView()
    private let aiNavStack = UIStackView()
    private let keyRowsStack = UIStackView()

    private var keyboardPage: KeyboardPage = .letters
    private var isShiftEnabled = false
    private var typedBuffer = ""
    private var toneIndex = 0
    private let tones = ["Casual", "Polite", "Formal", "Funny"]
    private var toneButton: MawaKeyButton?

    private let keyboardBackground = UIColor(red: 0.81, green: 0.83, blue: 0.87, alpha: 1.0)
    private let keyBackground = UIColor.white
    private let specialKeyBackground = UIColor(red: 0.67, green: 0.70, blue: 0.75, alpha: 1.0)
    private let aiBlue = UIColor(red: 0.02, green: 0.48, blue: 1.0, alpha: 1.0)
    private let keyText = UIColor.black

    override func viewDidLoad() {
        super.viewDidLoad()
        MawaDiagnostics.send(
            event: "keyboard_view_did_load",
            source: "keyboard",
            details: [
                "has_full_access": String(hasFullAccess),
                "needs_input_mode_switch_key": String(needsInputModeSwitchKey),
                "layout": "native_ios_keyboard_ai_nav_v1"
            ]
        )
        setupKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MawaDiagnostics.send(
            event: "keyboard_view_did_appear",
            source: "keyboard",
            details: ["has_full_access": String(hasFullAccess)]
        )
    }

    private func setupKeyboard() {
        view.backgroundColor = keyboardBackground
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 330).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.layoutMargins = UIEdgeInsets(top: 6, left: 3, bottom: 5, right: 3)
        rootStack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        buildAINavbar()

        keyRowsStack.axis = .vertical
        keyRowsStack.spacing = 7
        rootStack.addArrangedSubview(keyRowsStack)
        rebuildKeyRows()
    }

    private func buildAINavbar() {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.backgroundColor = keyboardBackground
        scrollView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        rootStack.addArrangedSubview(scrollView)

        aiNavStack.axis = .horizontal
        aiNavStack.spacing = 7
        aiNavStack.alignment = .center
        aiNavStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(aiNavStack)

        NSLayoutConstraint.activate([
            aiNavStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 4),
            aiNavStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -4),
            aiNavStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 2),
            aiNavStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -2),
            aiNavStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor, constant: -4)
        ])

        aiNavStack.addArrangedSubview(aiNavButton("✦ Rewrite", action: "rewrite", highlighted: true))
        toneButton = aiNavButton("Tone: \(tones[toneIndex])", action: "tone", highlighted: false)
        if let toneButton { aiNavStack.addArrangedSubview(toneButton) }
        aiNavStack.addArrangedSubview(aiNavButton("Reply", action: "reply", highlighted: false))
        aiNavStack.addArrangedSubview(aiNavButton("Prompt", action: "prompt", highlighted: false))
        aiNavStack.addArrangedSubview(aiNavButton("Translate", action: "translate", highlighted: false))
        aiNavStack.addArrangedSubview(aiNavButton("🎙 Dictate", action: "dictate", highlighted: false))
    }

    private func rebuildKeyRows() {
        keyRowsStack.arrangedSubviews.forEach { row in
            keyRowsStack.removeArrangedSubview(row)
            row.removeFromSuperview()
        }

        switch keyboardPage {
        case .letters:
            addLetterRow(Array("qwertyuiop").map(String.init), horizontalInset: 0)
            addLetterRow(Array("asdfghjkl").map(String.init), horizontalInset: 18)
            addLetterRowWithSpecials(Array("zxcvbnm").map(String.init))
            addBottomRow(leftTitle: "123")
        case .numbers:
            addLetterRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], horizontalInset: 0)
            addLetterRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""], horizontalInset: 0)
            addLetterRowWithSpecials([".", ",", "?", "!", "'"], leftTitle: "#+=", leftAction: "symbols")
            addBottomRow(leftTitle: "ABC")
        }
    }

    private func addLetterRow(_ letters: [String], horizontalInset: CGFloat) {
        let wrapper = UIStackView()
        wrapper.axis = .horizontal
        wrapper.spacing = 0
        wrapper.alignment = .fill

        if horizontalInset > 0 { wrapper.addArrangedSubview(fixedSpacer(width: horizontalInset)) }

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fillEqually
        for letter in letters {
            let value = keyboardPage == .letters && isShiftEnabled ? letter.uppercased() : letter
            row.addArrangedSubview(keyButton(value, value: value))
        }
        wrapper.addArrangedSubview(row)

        if horizontalInset > 0 { wrapper.addArrangedSubview(fixedSpacer(width: horizontalInset)) }
        keyRowsStack.addArrangedSubview(wrapper)
    }

    private func addLetterRowWithSpecials(_ letters: [String], leftTitle: String? = nil, leftAction: String = "shift") {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.alignment = .fill

        let left = keyButton(leftTitle ?? (isShiftEnabled ? "⇧" : "⇧"), specialAction: leftAction, isSpecial: true)
        left.widthAnchor.constraint(equalToConstant: 43).isActive = true
        row.addArrangedSubview(left)

        let middle = UIStackView()
        middle.axis = .horizontal
        middle.spacing = 5
        middle.distribution = .fillEqually
        for letter in letters {
            let value = keyboardPage == .letters && isShiftEnabled ? letter.uppercased() : letter
            middle.addArrangedSubview(keyButton(value, value: value))
        }
        row.addArrangedSubview(middle)

        let delete = keyButton("⌫", specialAction: "delete", isSpecial: true)
        delete.widthAnchor.constraint(equalToConstant: 43).isActive = true
        row.addArrangedSubview(delete)

        keyRowsStack.addArrangedSubview(row)
    }

    private func addBottomRow(leftTitle: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.alignment = .fill

        let page = keyButton(leftTitle, specialAction: "page", isSpecial: true)
        page.widthAnchor.constraint(equalToConstant: 48).isActive = true
        row.addArrangedSubview(page)

        let globe = keyButton("🌐", specialAction: "globe", isSpecial: true)
        globe.widthAnchor.constraint(equalToConstant: 40).isActive = true
        row.addArrangedSubview(globe)

        let space = keyButton("space", specialAction: "space", isSpecial: false)
        space.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        row.addArrangedSubview(space)

        let returnKey = keyButton("return", specialAction: "return", isSpecial: true)
        returnKey.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        returnKey.widthAnchor.constraint(equalToConstant: 78).isActive = true
        row.addArrangedSubview(returnKey)

        keyRowsStack.addArrangedSubview(row)
    }

    private func aiNavButton(_ title: String, action: String, highlighted: Bool) -> MawaKeyButton {
        let button = MawaKeyButton(type: .system)
        button.specialAction = action
        button.setTitle(title, for: .normal)
        button.setTitleColor(highlighted ? .white : .label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = highlighted ? aiBlue : UIColor.white.withAlphaComponent(0.86)
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = highlighted ? 0.12 : 0.08
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 13, bottom: 8, right: 13)
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.addTarget(self, action: #selector(handleButton(_:)), for: .touchUpInside)
        return button
    }

    private func keyButton(_ title: String, value: String = "", specialAction: String = "", isSpecial: Bool = false) -> MawaKeyButton {
        let button = MawaKeyButton(type: .system)
        button.keyValue = value
        button.specialAction = specialAction
        button.setTitle(title, for: .normal)
        button.setTitleColor(keyText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 21, weight: .regular)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.backgroundColor = isSpecial ? specialKeyBackground : keyBackground
        button.layer.cornerRadius = 5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.20
        button.layer.shadowRadius = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.heightAnchor.constraint(equalToConstant: 43).isActive = true
        button.addTarget(self, action: #selector(handleButton(_:)), for: .touchUpInside)
        return button
    }

    private func fixedSpacer(width: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(equalToConstant: width).isActive = true
        return spacer
    }

    @objc private func handleButton(_ sender: MawaKeyButton) {
        switch sender.specialAction {
        case "delete":
            textDocumentProxy.deleteBackward()
            if !typedBuffer.isEmpty { typedBuffer.removeLast() }
        case "shift":
            isShiftEnabled.toggle()
            rebuildKeyRows()
        case "page", "symbols":
            keyboardPage = keyboardPage == .letters ? .numbers : .letters
            rebuildKeyRows()
        case "space":
            insertText(" ")
        case "return":
            insertText("\n")
        case "globe":
            advanceToNextInputMode()
        case "tone":
            toneIndex = (toneIndex + 1) % tones.count
            toneButton?.setTitle("Tone: \(tones[toneIndex])", for: .normal)
            MawaDiagnostics.send(event: "keyboard_tone_changed", source: "keyboard", details: ["tone": tones[toneIndex]])
        case "rewrite":
            performAI(mode: .rewrite, event: "keyboard_ai_rewrite_tapped")
        case "reply":
            performAI(mode: .reply, event: "keyboard_ai_reply_tapped")
        case "prompt":
            performAI(mode: .prompt, event: "keyboard_ai_prompt_tapped")
        case "translate":
            insertOrReplaceWithAIText("Translate mode is coming next. For now, rewrite or prompt mode is ready.", event: "keyboard_ai_translate_tapped")
        case "dictate":
            insertOrReplaceWithAIText("Voice dictation is coming next — the native keyboard layout is active now.", event: "keyboard_ai_dictate_tapped")
        default:
            if !sender.keyValue.isEmpty {
                insertText(sender.keyValue)
                if isShiftEnabled && keyboardPage == .letters {
                    isShiftEnabled = false
                    rebuildKeyRows()
                }
            }
        }
    }

    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        typedBuffer += text
        if typedBuffer.count > 700 {
            typedBuffer = String(typedBuffer.suffix(700))
        }
    }

    private func performAI(mode: MawaMode, event: String) {
        let source = sourceTextForAI()
        let result = MawaFlowEngine.generate(draft: source, requestedMode: mode)
        insertOrReplaceWithAIText(applySelectedTone(to: result.output), event: event)
    }

    private func insertOrReplaceWithAIText(_ text: String, event: String) {
        MawaDiagnostics.send(event: event, source: "keyboard", details: ["tone": tones[toneIndex]])
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !typedBuffer.isEmpty {
            for _ in typedBuffer { textDocumentProxy.deleteBackward() }
        }
        textDocumentProxy.insertText(trimmed)
        typedBuffer = trimmed
    }

    private func sourceTextForAI() -> String {
        let local = typedBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !local.isEmpty { return local }
        if let before = textDocumentProxy.documentContextBeforeInput?.trimmingCharacters(in: .whitespacesAndNewlines), !before.isEmpty {
            return String(before.suffix(240))
        }
        return MawaFlowEngine.defaultDraft
    }

    private func applySelectedTone(to text: String) -> String {
        switch tones[toneIndex] {
        case "Polite":
            return text.hasPrefix("Please") ? text : "Please " + text.prefix(1).lowercased() + String(text.dropFirst())
        case "Formal":
            return text.replacingOccurrences(of: "Hey — ", with: "Hello, ")
        case "Funny":
            return text + " 😄"
        default:
            return text
        }
    }
}
