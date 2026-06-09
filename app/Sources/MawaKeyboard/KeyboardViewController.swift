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

    private let modes: [MawaMode] = [.rewrite, .dictate, .reply, .prompt, .ask]
    private let tones = ["Grammar", "Formal", "Social", "Casual", "Funny", "Polite"]

    private var selectedMode: MawaMode = .rewrite
    private var selectedTone = "Casual"
    private var keyboardPage: KeyboardPage = .letters
    private var isShiftEnabled = false
    private var typedBuffer = ""
    private var previewText = "Tap AI Rephrase to polish nearby text or what you type here."
    private var variant = 0

    private let rootStack = UIStackView()
    private let toolbarStack = UIStackView()
    private let aiPanel = UIStackView()
    private let toneStack = UIStackView()
    private let keysStack = UIStackView()
    private let sourceLabel = UILabel()
    private let outputLabel = UILabel()
    private let contextLabel = UILabel()

    private let blue = UIColor(red: 0.04, green: 0.52, blue: 0.96, alpha: 1.0)
    private let dark = UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
    private let keyBackground = UIColor.white.withAlphaComponent(0.94)
    private let specialBackground = UIColor(red: 0.80, green: 0.82, blue: 0.86, alpha: 1.0)
    private let keyboardBackground = UIColor(red: 0.86, green: 0.88, blue: 0.91, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        MawaDiagnostics.send(
            event: "keyboard_view_did_load",
            source: "keyboard",
            details: [
                "has_full_access": String(hasFullAccess),
                "needs_input_mode_switch_key": String(needsInputModeSwitchKey),
                "layout": "qwerty_ai_controls_v1"
            ]
        )
        setupKeyboard()
        refreshAI(copyFromContext: true)
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
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 372).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 6
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.layoutMargins = UIEdgeInsets(top: 8, left: 6, bottom: 6, right: 6)
        rootStack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        buildToolbar()
        buildAIPanel()
        rebuildKeyboardRows()
    }

    private func buildToolbar() {
        toolbarStack.axis = .horizontal
        toolbarStack.spacing = 6
        toolbarStack.alignment = .fill
        toolbarStack.distribution = .fillProportionally
        rootStack.addArrangedSubview(toolbarStack)

        let menu = toolbarButton("☷", action: "ai", highlighted: false)
        menu.setTitleColor(.darkGray, for: .normal)
        menu.widthAnchor.constraint(equalToConstant: 42).isActive = true
        toolbarStack.addArrangedSubview(menu)

        let rephrase = toolbarButton("✦ AI Rephrase", action: "ai", highlighted: true)
        toolbarStack.addArrangedSubview(rephrase)

        let translate = toolbarButton("◎ Translate", action: "translate", highlighted: false)
        toolbarStack.addArrangedSubview(translate)

        let undo = toolbarButton("↶", action: "delete", highlighted: false)
        undo.widthAnchor.constraint(equalToConstant: 42).isActive = true
        toolbarStack.addArrangedSubview(undo)

        let mic = toolbarButton("●", action: "mic", highlighted: false)
        mic.widthAnchor.constraint(equalToConstant: 42).isActive = true
        toolbarStack.addArrangedSubview(mic)
    }

    private func buildAIPanel() {
        aiPanel.axis = .vertical
        aiPanel.spacing = 7
        aiPanel.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        aiPanel.isLayoutMarginsRelativeArrangement = true
        aiPanel.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)
        aiPanel.layer.cornerRadius = 14
        rootStack.addArrangedSubview(aiPanel)

        let topLine = UIStackView()
        topLine.axis = .horizontal
        topLine.alignment = .center
        topLine.spacing = 6

        let title = UILabel()
        title.text = "Source Text"
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = UIColor.white.withAlphaComponent(0.62)
        topLine.addArrangedSubview(title)

        contextLabel.text = "Cursor/local"
        contextLabel.font = .systemFont(ofSize: 11, weight: .medium)
        contextLabel.textAlignment = .right
        contextLabel.textColor = UIColor.white.withAlphaComponent(0.48)
        topLine.addArrangedSubview(contextLabel)
        aiPanel.addArrangedSubview(topLine)

        sourceLabel.numberOfLines = 2
        sourceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sourceLabel.textColor = .white
        sourceLabel.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
        sourceLabel.layer.cornerRadius = 10
        sourceLabel.layer.masksToBounds = true
        aiPanel.addArrangedSubview(padded(sourceLabel, inset: 9, background: UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0), cornerRadius: 10, minHeight: 46))

        toneStack.axis = .horizontal
        toneStack.spacing = 5
        toneStack.distribution = .fillEqually
        aiPanel.addArrangedSubview(toneStack)
        rebuildToneButtons()

        let outputRow = UIStackView()
        outputRow.axis = .horizontal
        outputRow.spacing = 8
        outputRow.alignment = .fill

        outputLabel.numberOfLines = 3
        outputLabel.font = .systemFont(ofSize: 14, weight: .regular)
        outputLabel.textColor = .white
        outputLabel.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
        outputLabel.layer.cornerRadius = 12
        outputLabel.layer.masksToBounds = true
        outputRow.addArrangedSubview(padded(outputLabel, inset: 10, background: UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0), cornerRadius: 12, minHeight: 52))

        let insert = compactActionButton("Insert", action: "insert_ai")
        insert.widthAnchor.constraint(equalToConstant: 72).isActive = true
        outputRow.addArrangedSubview(insert)
        aiPanel.addArrangedSubview(outputRow)
    }

    private func rebuildToneButtons() {
        toneStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tone in tones {
            let button = compactActionButton(tone, action: "tone")
            button.keyValue = tone
            if tone == selectedTone {
                button.backgroundColor = blue
                button.setTitleColor(.white, for: .normal)
            }
            toneStack.addArrangedSubview(button)
        }
    }

    private func rebuildKeyboardRows() {
        keysStack.removeFromSuperview()
        keysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keysStack.axis = .vertical
        keysStack.spacing = 6
        rootStack.addArrangedSubview(keysStack)

        switch keyboardPage {
        case .letters:
            addKeyRow(Array("qwertyuiop").map(String.init))
            addKeyRow(Array("asdfghjkl").map(String.init), sideInset: 18)
            addKeyRow(Array("zxcvbnm").map(String.init), leadingSpecial: (isShiftEnabled ? "⇧" : "⇧", "shift"), trailingSpecial: ("⌫", "delete"))
            addBottomRow(pageTitle: "123")
        case .numbers:
            addKeyRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
            addKeyRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""])
            addKeyRow([".", ",", "?", "!", "'"], leadingSpecial: ("#+=", "symbols"), trailingSpecial: ("⌫", "delete"))
            addBottomRow(pageTitle: "ABC")
        }
    }

    private func addKeyRow(_ keys: [String], sideInset: CGFloat = 0, leadingSpecial: (String, String)? = nil, trailingSpecial: (String, String)? = nil) {
        let outer = UIStackView()
        outer.axis = .horizontal
        outer.spacing = 5
        outer.alignment = .fill
        outer.distribution = .fill

        if sideInset > 0 {
            outer.addArrangedSubview(spacer(width: sideInset))
        }
        if let leadingSpecial {
            let button = keyButton(leadingSpecial.0, specialAction: leadingSpecial.1, isSpecial: true)
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            outer.addArrangedSubview(button)
        }
        for key in keys {
            let title = keyboardPage == .letters && isShiftEnabled ? key.uppercased() : key
            outer.addArrangedSubview(keyButton(title, value: title))
        }
        if let trailingSpecial {
            let button = keyButton(trailingSpecial.0, specialAction: trailingSpecial.1, isSpecial: true)
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            outer.addArrangedSubview(button)
        }
        if sideInset > 0 {
            outer.addArrangedSubview(spacer(width: sideInset))
        }
        keysStack.addArrangedSubview(outer)
    }

    private func addBottomRow(pageTitle: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.alignment = .fill

        let page = keyButton(pageTitle, specialAction: "page", isSpecial: true)
        page.widthAnchor.constraint(equalToConstant: 48).isActive = true
        row.addArrangedSubview(page)

        let globe = keyButton("🌐", specialAction: "globe", isSpecial: true)
        globe.widthAnchor.constraint(equalToConstant: 42).isActive = true
        row.addArrangedSubview(globe)

        let space = keyButton("Mawa Flow", specialAction: "space", isSpecial: false)
        space.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        row.addArrangedSubview(space)

        let returnKey = keyButton("return", specialAction: "return", isSpecial: true)
        returnKey.widthAnchor.constraint(equalToConstant: 66).isActive = true
        row.addArrangedSubview(returnKey)

        let mic = keyButton("🎙", specialAction: "mic", isSpecial: true)
        mic.widthAnchor.constraint(equalToConstant: 42).isActive = true
        row.addArrangedSubview(mic)

        keysStack.addArrangedSubview(row)
    }

    private func toolbarButton(_ title: String, action: String, highlighted: Bool) -> MawaKeyButton {
        let button = MawaKeyButton(type: .system)
        button.specialAction = action
        button.setTitle(title, for: .normal)
        button.setTitleColor(highlighted ? .white : UIColor.white.withAlphaComponent(0.88), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = highlighted ? blue : dark.withAlphaComponent(0.92)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        button.addTarget(self, action: #selector(handleButton(_:)), for: .touchUpInside)
        return button
    }

    private func compactActionButton(_ title: String, action: String) -> MawaKeyButton {
        let button = MawaKeyButton(type: .system)
        button.specialAction = action
        button.setTitle(title, for: .normal)
        button.setTitleColor(blue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.20, green: 0.22, blue: 0.25, alpha: 1.0)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        button.addTarget(self, action: #selector(handleButton(_:)), for: .touchUpInside)
        return button
    }

    private func keyButton(_ title: String, value: String = "", specialAction: String = "", isSpecial: Bool = false) -> MawaKeyButton {
        let button = MawaKeyButton(type: .system)
        button.keyValue = value
        button.specialAction = specialAction
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        button.backgroundColor = isSpecial ? specialBackground : keyBackground
        button.layer.cornerRadius = 6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowRadius = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.addTarget(self, action: #selector(handleButton(_:)), for: .touchUpInside)
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

    private func spacer(width: CGFloat) -> UIView {
        let view = UIView()
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view
    }

    @objc private func handleButton(_ sender: MawaKeyButton) {
        switch sender.specialAction {
        case "delete":
            textDocumentProxy.deleteBackward()
            if !typedBuffer.isEmpty { typedBuffer.removeLast() }
            refreshAI(copyFromContext: false)
        case "shift":
            isShiftEnabled.toggle()
            rebuildKeyboardRows()
        case "page", "symbols":
            keyboardPage = keyboardPage == .letters ? .numbers : .letters
            rebuildKeyboardRows()
        case "space":
            insertText(" ")
        case "return":
            insertText("\n")
        case "globe":
            advanceToNextInputMode()
        case "ai":
            selectedMode = .rewrite
            refreshAI(copyFromContext: true)
            MawaDiagnostics.send(event: "keyboard_ai_rephrase_tapped", source: "keyboard")
        case "translate":
            selectedMode = .ask
            selectedTone = "Translate"
            refreshAI(copyFromContext: true)
            MawaDiagnostics.send(event: "keyboard_translate_tapped", source: "keyboard")
        case "tone":
            selectedTone = sender.keyValue
            rebuildToneButtons()
            refreshAI(copyFromContext: false)
        case "insert_ai":
            MawaDiagnostics.send(event: "keyboard_ai_insert_tapped", source: "keyboard")
            textDocumentProxy.insertText(previewText)
            typedBuffer = ""
            refreshAI(copyFromContext: true)
        case "mic":
            MawaDiagnostics.send(event: "keyboard_mic_placeholder_tapped", source: "keyboard")
            sourceLabel.text = "Voice mode is next. For now, type normally or tap AI Rephrase."
            outputLabel.text = "Voice capture coming next — the full keyboard and AI controls are active in this build."
        default:
            if !sender.keyValue.isEmpty {
                insertText(sender.keyValue)
                if isShiftEnabled && keyboardPage == .letters {
                    isShiftEnabled = false
                    rebuildKeyboardRows()
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
        refreshAI(copyFromContext: false)
    }

    private func refreshAI(copyFromContext: Bool) {
        let source = currentSourceText(copyFromContext: copyFromContext)
        sourceLabel.text = source.isEmpty ? "Type something, then choose a tone or tap AI Rephrase." : source
        contextLabel.text = sourceContextLabel()

        if selectedTone == "Translate" {
            previewText = "Translate mode selected. Next build will choose language; for now, Mawa can rewrite the source clearly."
        } else {
            let result = MawaFlowEngine.generate(draft: source, requestedMode: selectedMode, variant: variant)
            previewText = applyTone(selectedTone, to: result.output)
            variant += 1
        }
        outputLabel.text = previewText
    }

    private func currentSourceText(copyFromContext: Bool) -> String {
        if !typedBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return typedBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if copyFromContext, let before = textDocumentProxy.documentContextBeforeInput?.trimmingCharacters(in: .whitespacesAndNewlines), !before.isEmpty {
            return String(before.suffix(240))
        }
        return ""
    }

    private func sourceContextLabel() -> String {
        if !typedBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Local typing" }
        if let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty { return "Cursor context" }
        return "No text yet"
    }

    private func applyTone(_ tone: String, to text: String) -> String {
        switch tone {
        case "Grammar":
            return text
        case "Formal":
            return text.replacingOccurrences(of: "Hey — ", with: "Hello, ")
        case "Social":
            return text + " 🙌"
        case "Casual":
            return text
        case "Funny":
            return text + " 😄"
        case "Polite":
            return text.hasPrefix("Please") ? text : "Please " + text.prefix(1).lowercased() + String(text.dropFirst())
        default:
            return text
        }
    }
}
