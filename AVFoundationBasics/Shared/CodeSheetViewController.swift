import UIKit

// MARK: - CodeSheetViewController

class CodeSheetViewController: UIViewController {

    private let code: String
    private var textView: UITextView!

    // MARK: - Init

    init(code: String) {
        self.code = code
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyHighlighting()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)

        title = "Swift Code"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.12, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        textView.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func applyHighlighting() {
        textView.attributedText = syntaxHighlight(code)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Syntax Highlighting

    private func syntaxHighlight(_ source: String) -> NSAttributedString {
        let defaultColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1) // #E8E8E8
        let keywordColor = UIColor(red: 0.831, green: 0.612, blue: 0.961, alpha: 1) // #D49CF5
        let typeColor = UIColor(red: 0.298, green: 0.851, blue: 1.0, alpha: 1)     // #4CD9FF
        let stringColor = UIColor(red: 1.0, green: 0.690, blue: 0.404, alpha: 1)   // #FFB067
        let commentColor = UIColor(red: 0.427, green: 0.788, blue: 0.427, alpha: 1) // #6DC96D

        let keywords: Set<String> = [
            "let", "var", "func", "class", "struct", "import", "return",
            "if", "else", "for", "in", "while", "guard", "switch", "case",
            "true", "false", "nil", "self", "async", "await", "throws",
            "try", "override", "private", "public", "static", "weak", "lazy"
        ]

        let types: Set<String> = [
            "AVAudioPlayer", "AVAudioRecorder", "AVAudioSession", "AVAudioEngine",
            "AVSpeechSynthesizer", "AVSpeechUtterance", "AVAsset", "AVPlayer",
            "AVCaptureSession", "URLSession", "String", "Int", "Double",
            "Float", "Bool", "Data"
        ]

        let result = NSMutableAttributedString()
        let monoFont = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        // Split into lines to handle comments
        let lines = source.components(separatedBy: "\n")

        for (lineIndex, line) in lines.enumerated() {
            if lineIndex > 0 {
                result.append(NSAttributedString(string: "\n", attributes: [
                    .font: monoFont,
                    .foregroundColor: defaultColor
                ]))
            }

            // Check if line is a comment
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") {
                result.append(NSAttributedString(string: line, attributes: [
                    .font: monoFont,
                    .foregroundColor: commentColor
                ]))
                continue
            }

            // Tokenize line: handle strings and words
            let lineAttr = tokenizeLine(
                line,
                defaultColor: defaultColor,
                keywordColor: keywordColor,
                typeColor: typeColor,
                stringColor: stringColor,
                commentColor: commentColor,
                keywords: keywords,
                types: types,
                font: monoFont
            )
            result.append(lineAttr)
        }

        return result
    }

    private func tokenizeLine(
        _ line: String,
        defaultColor: UIColor,
        keywordColor: UIColor,
        typeColor: UIColor,
        stringColor: UIColor,
        commentColor: UIColor,
        keywords: Set<String>,
        types: Set<String>,
        font: UIFont
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var idx = line.startIndex

        while idx < line.endIndex {
            let ch = line[idx]

            // Inline comment
            if ch == "/" {
                let next = line.index(after: idx)
                if next < line.endIndex && line[next] == "/" {
                    let remainder = String(line[idx...])
                    result.append(NSAttributedString(string: remainder, attributes: [
                        .font: font,
                        .foregroundColor: commentColor
                    ]))
                    return result
                }
            }

            // String literal
            if ch == "\"" {
                var strEnd = line.index(after: idx)
                var escaped = false
                while strEnd < line.endIndex {
                    let sc = line[strEnd]
                    if escaped {
                        escaped = false
                    } else if sc == "\\" {
                        escaped = true
                    } else if sc == "\"" {
                        strEnd = line.index(after: strEnd)
                        break
                    }
                    strEnd = line.index(after: strEnd)
                }
                let strToken = String(line[idx..<strEnd])
                result.append(NSAttributedString(string: strToken, attributes: [
                    .font: font,
                    .foregroundColor: stringColor
                ]))
                idx = strEnd
                continue
            }

            // Word token
            if ch.isLetter || ch == "_" {
                var wordEnd = idx
                while wordEnd < line.endIndex && (line[wordEnd].isLetter || line[wordEnd].isNumber || line[wordEnd] == "_") {
                    wordEnd = line.index(after: wordEnd)
                }
                let word = String(line[idx..<wordEnd])
                let color: UIColor
                if keywords.contains(word) {
                    color = keywordColor
                } else if types.contains(word) {
                    color = typeColor
                } else {
                    color = defaultColor
                }
                result.append(NSAttributedString(string: word, attributes: [
                    .font: font,
                    .foregroundColor: color
                ]))
                idx = wordEnd
                continue
            }

            // Default character
            result.append(NSAttributedString(string: String(ch), attributes: [
                .font: font,
                .foregroundColor: defaultColor
            ]))
            idx = line.index(after: idx)
        }

        return result
    }

    // MARK: - Static Helper

    static func showCodeSheet(from vc: UIViewController, code: String) {
        let codeVC = CodeSheetViewController(code: code)
        let nav = UINavigationController(rootViewController: codeVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        vc.present(nav, animated: true)
    }
}
