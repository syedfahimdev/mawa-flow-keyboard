import UIKit

final class KeyboardViewController: UIInputViewController {
    private let modes: [MawaMode] = [.auto, .dictate, .reply, .prompt, .rewrite]
    private var selectedMode: MawaMode = .auto
    private var draft: String = MawaFlowEngine.defaultDraft
    private var previewText: String = "Tap Mawa to generate a local Phase 1 preview."
    private var variant: Int = 0

    private let previewLabel = UILabel()
    private let intentLabel = UILabel()
    private let statusLabel = UILabel()
    private let mawaButton = UIButton(type: .system)
    private let modeStack = UIStackView()
    private let sampleStack = UIStackView()

    private let teal = UIColor(red: 0.02, green: 0.42, blue: 0.35, alpha: 1.0)
    private let ivory = UIColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 1.0)
    private let violet = UIColor(red: 0.73, green: 0.58, blue: 1.0, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
        generatePreview()
    }

    private func setupKeyboard() {
        view.backgroundColor = ivory
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 310).isActive = true

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 10
        root.translatesAutoresizingMaskIntoConstraints = false
        root.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 8, right: 10)
        root.isLayoutMarginsRelativeArrangement = true
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let header = UIStackView()
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center

        let title = UILabel()
        title.text = "Mawa Flow"
        title.font = .systemFont(ofSize: 15, weight: .bold)
        title.textColor = teal
        header.addArrangedSubview(title)

        statusLabel.text = "Local demo"
        statusLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .right
        header.addArrangedSubview(statusLabel)
        root.addArrangedSubview(header)

        modeStack.axis = .horizontal
        modeStack.spacing = 6
        modeStack.distribution = .fillEqually
        root.addArrangedSubview(modeStack)
        rebuildModeButtons()

        previewLabel.text = previewText
        previewLabel.font = .systemFont(ofSize: 15, weight: .regular)
        previewLabel.textColor = .label
        previewLabel.numberOfLines = 4
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.backgroundColor = .white
        previewLabel.layer.cornerRadius = 18
        previewLabel.layer.masksToBounds = true
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        root.addArrangedSubview(wrapWithPadding(previewLabel, inset: 14, background: .white, cornerRadius: 18))

        intentLabel.text = "Intent: Auto • Context: none"
        intentLabel.font = .systemFont(ofSize: 12, weight: .medium)
        intentLabel.textColor = .secondaryLabel
        root.addArrangedSubview(intentLabel)

        sampleStack.axis = .horizontal
        sampleStack.spacing = 6
        sampleStack.distribution = .fillEqually
        root.addArrangedSubview(sampleStack)
        rebuildSampleButtons()

        let actionRow = UIStackView()
        actionRow.axis = .horizontal
        actionRow.spacing = 8
        actionRow.distribution = .fillProportionally

        let nextKeyboard = smallButton("🌐")
        nextKeyboard.addTarget(self, action: #selector(handleNextKeyboard), for: .touchUpInside)
        actionRow.addArrangedSubview(nextKeyboard)

        let clearButton = smallButton("Clear")
        clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        actionRow.addArrangedSubview(clearButton)

        mawaButton.setTitle("Hold Mawa / Generate", for: .normal)
        mawaButton.setTitleColor(.white, for: .normal)
        mawaButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        mawaButton.backgroundColor = teal
        mawaButton.layer.cornerRadius = 18
        mawaButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        mawaButton.addTarget(self, action: #selector(handleGenerate), for: .touchUpInside)
        actionRow.addArrangedSubview(mawaButton)

        let insertButton = smallButton("Insert")
        insertButton.backgroundColor = violet.withAlphaComponent(0.35)
        insertButton.addTarget(self, action: #selector(handleInsert), for: .touchUpInside)
        actionRow.addArrangedSubview(insertButton)

        root.addArrangedSubview(actionRow)

        let transformRow = UIStackView()
        transformRow.axis = .horizontal
        transformRow.spacing = 8
        transformRow.distribution = .fillEqually

        let shorter = smallButton("Shorter")
        shorter.addTarget(self, action: #selector(handleShorter), for: .touchUpInside)
        transformRow.addArrangedSubview(shorter)

        let warmer = smallButton("Warmer")
        warmer.addTarget(self, action: #selector(handleWarmer), for: .touchUpInside)
        transformRow.addArrangedSubview(warmer)

        let redo = smallButton("Regenerate")
        redo.addTarget(self, action: #selector(handleGenerate), for: .touchUpInside)
        transformRow.addArrangedSubview(redo)

        root.addArrangedSubview(transformRow)
    }

    private func rebuildModeButtons() {
        modeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for mode in modes {
            let button = smallButton(mode.shortLabel)
            button.backgroundColor = mode == selectedMode ? teal : .white
            button.setTitleColor(mode == selectedMode ? .white : teal, for: .normal)
            button.tag = modes.firstIndex(of: mode) ?? 0
            button.addTarget(self, action: #selector(handleMode(_:)), for: .touchUpInside)
            modeStack.addArrangedSubview(button)
        }
    }

    private func rebuildSampleButtons() {
        sampleStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, sample) in MawaFlowEngine.demoSamples.prefix(3).enumerated() {
            let button = smallButton(sample.title)
            button.tag = index
            button.addTarget(self, action: #selector(handleSample(_:)), for: .touchUpInside)
            sampleStack.addArrangedSubview(button)
        }
    }

    private func smallButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.setTitleColor(teal, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        return button
    }

    private func wrapWithPadding(_ label: UILabel, inset: CGFloat, background: UIColor, cornerRadius: CGFloat) -> UIView {
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
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 92)
        ])
        return container
    }

    private func generatePreview() {
        let result = MawaFlowEngine.generate(draft: draft, requestedMode: selectedMode, variant: variant)
        previewText = result.output
        previewLabel.text = result.output
        intentLabel.text = "Intent: \(result.intentLabel) • Context: none"
        statusLabel.text = result.privacyLabel
        variant += 1
    }

    @objc private func handleMode(_ sender: UIButton) {
        selectedMode = modes[sender.tag]
        rebuildModeButtons()
        generatePreview()
    }

    @objc private func handleSample(_ sender: UIButton) {
        let sample = Array(MawaFlowEngine.demoSamples.prefix(3))[sender.tag]
        draft = sample.text
        selectedMode = sample.mode
        rebuildModeButtons()
        generatePreview()
    }

    @objc private func handleGenerate() {
        generatePreview()
    }

    @objc private func handleInsert() {
        textDocumentProxy.insertText(previewText)
    }

    @objc private func handleClear() {
        previewText = "Tap Mawa to generate a local Phase 1 preview."
        previewLabel.text = previewText
        intentLabel.text = "Intent: none • Context: none"
    }

    @objc private func handleShorter() {
        previewText = MawaFlowEngine.shorter(previewText)
        previewLabel.text = previewText
    }

    @objc private func handleWarmer() {
        previewText = MawaFlowEngine.warmer(previewText)
        previewLabel.text = previewText
    }

    @objc private func handleNextKeyboard() {
        advanceToNextInputMode()
    }
}
