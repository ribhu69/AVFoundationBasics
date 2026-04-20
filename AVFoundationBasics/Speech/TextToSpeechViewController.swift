import UIKit
import AVFoundation
import SwiftUI

// MARK: - TextToSpeechViewController

class TextToSpeechViewController: UIViewController {

    // MARK: - AVFoundation
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let inputTextView = UITextView()
    private let rateSlider = UISlider()
    private let rateLabel = UILabel()
    private let pitchSlider = UISlider()
    private let pitchLabel = UILabel()
    private let volumeSlider = UISlider()
    private let volumeLabel = UILabel()
    private let languagePicker = UISegmentedControl(items: ["English", "Spanish", "French"])
    private let speakButton = UIButton(type: .system)
    private let pauseResumeButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    private let languages = ["en-US", "es-ES", "fr-FR"]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Text to Speech"
        view.backgroundColor = .systemBackground
        synthesizer.delegate = self
        setupNavBar()
        setupScrollView()
        setupStack()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Nav Bar

    private func setupNavBar() {
        let codeButton = UIBarButtonItem(
            title: "{ } Code",
            style: .plain,
            target: self,
            action: #selector(showCode)
        )
        let swiftUIButton = UIBarButtonItem(
            title: "SwiftUI",
            style: .plain,
            target: self,
            action: #selector(showSwiftUI)
        )
        navigationItem.rightBarButtonItems = [swiftUIButton, codeButton]
    }

    // MARK: - ScrollView + Stack

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupStack() {
        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // Text input
        stackView.addArrangedSubview(makeSectionLabel("Text to Speak"))
        inputTextView.text = "Welcome to AVFoundation. AVSpeechSynthesizer converts text to speech with control over rate, pitch, and language."
        inputTextView.font = UIFont.systemFont(ofSize: 15)
        inputTextView.layer.borderColor = UIColor.systemGray4.cgColor
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.cornerRadius = 8
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        inputTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stackView.addArrangedSubview(inputTextView)

        // Rate slider
        stackView.addArrangedSubview(makeSectionLabel("Speech Parameters"))
        rateLabel.text = String(format: "Rate: %.2f", AVSpeechUtteranceDefaultSpeechRate)
        rateLabel.font = UIFont.systemFont(ofSize: 13)
        rateLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(rateLabel)

        rateSlider.minimumValue = 0.1
        rateSlider.maximumValue = 0.9
        rateSlider.value = AVSpeechUtteranceDefaultSpeechRate
        rateSlider.addTarget(self, action: #selector(rateChanged), for: .valueChanged)
        stackView.addArrangedSubview(rateSlider)

        // Pitch slider
        pitchLabel.text = "Pitch: 1.00"
        pitchLabel.font = UIFont.systemFont(ofSize: 13)
        pitchLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(pitchLabel)

        pitchSlider.minimumValue = 0.5
        pitchSlider.maximumValue = 2.0
        pitchSlider.value = 1.0
        pitchSlider.addTarget(self, action: #selector(pitchChanged), for: .valueChanged)
        stackView.addArrangedSubview(pitchSlider)

        // Volume slider
        volumeLabel.text = "Volume: 1.00"
        volumeLabel.font = UIFont.systemFont(ofSize: 13)
        volumeLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(volumeLabel)

        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 1.0
        volumeSlider.value = 1.0
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        stackView.addArrangedSubview(volumeSlider)

        // Language picker
        stackView.addArrangedSubview(makeSectionLabel("Language"))
        languagePicker.selectedSegmentIndex = 0
        stackView.addArrangedSubview(languagePicker)

        // Buttons
        stackView.addArrangedSubview(makeSectionLabel("Controls"))

        speakButton.setTitle("Speak", for: .normal)
        speakButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        speakButton.addTarget(self, action: #selector(speakTapped), for: .touchUpInside)

        pauseResumeButton.setTitle("Pause", for: .normal)
        pauseResumeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        pauseResumeButton.isEnabled = false
        pauseResumeButton.addTarget(self, action: #selector(pauseResumeTapped), for: .touchUpInside)

        stopButton.setTitle("Stop", for: .normal)
        stopButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        stopButton.isEnabled = false
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [speakButton, pauseResumeButton, stopButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 8
        stackView.addArrangedSubview(buttonRow)

        // Status
        stackView.addArrangedSubview(makeSectionLabel("Status"))
        statusLabel.text = "Idle"
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(statusLabel)

        // Info
        stackView.addArrangedSubview(makeSectionLabel("About"))
        let infoLabel = UILabel()
        infoLabel.text = "AVSpeechSynthesizer converts text to spoken audio. Customize rate (speed), pitch multiplier, volume, and voice language. Implement AVSpeechSynthesizerDelegate to track speech events."
        infoLabel.font = UIFont.systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stackView.addArrangedSubview(infoLabel)
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }

    // MARK: - Actions

    @objc private func rateChanged() {
        rateLabel.text = String(format: "Rate: %.2f", rateSlider.value)
    }

    @objc private func pitchChanged() {
        pitchLabel.text = String(format: "Pitch: %.2f", pitchSlider.value)
    }

    @objc private func volumeChanged() {
        volumeLabel.text = String(format: "Volume: %.2f", volumeSlider.value)
    }

    @objc private func speakTapped() {
        synthesizer.stopSpeaking(at: .immediate)
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rateSlider.value
        utterance.pitchMultiplier = pitchSlider.value
        utterance.volume = volumeSlider.value

        let langCode = languages[languagePicker.selectedSegmentIndex]
        utterance.voice = AVSpeechSynthesisVoice(language: langCode)

        synthesizer.speak(utterance)
    }

    @objc private func pauseResumeTapped() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .word)
            pauseResumeButton.setTitle("Resume", for: .normal)
            statusLabel.text = "Paused"
        } else if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            pauseResumeButton.setTitle("Pause", for: .normal)
            statusLabel.text = "Speaking..."
        }
    }

    @objc private func stopTapped() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    @objc private func showCode() {
        let snippet = """
import AVFoundation

// Create synthesizer and set delegate
let synthesizer = AVSpeechSynthesizer()
synthesizer.delegate = self

// Build utterance with text
let utterance = AVSpeechUtterance(string: "Hello, AVFoundation!")

// Configure speech parameters
utterance.rate = AVSpeechUtteranceDefaultSpeechRate  // 0.1...0.9
utterance.pitchMultiplier = 1.0  // 0.5...2.0
utterance.volume = 1.0           // 0.0...1.0

// Select a voice by language code
utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

// Speak
synthesizer.speak(utterance)

// Pause at word boundary
synthesizer.pauseSpeaking(at: .word)

// Resume
synthesizer.continueSpeaking()

// Stop immediately
synthesizer.stopSpeaking(at: .immediate)

// MARK: - AVSpeechSynthesizerDelegate
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didStart utterance: AVSpeechUtterance) { }
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didFinish utterance: AVSpeechUtterance) { }
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didPause utterance: AVSpeechUtterance) { }
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                        didContinue utterance: AVSpeechUtterance) { }
"""
        CodeSheetViewController.showCodeSheet(from: self, code: snippet)
    }

    @objc private func showSwiftUI() {
        let swiftUIView = TextToSpeechSwiftUIView()
        let hostingVC = UIHostingController(rootView: swiftUIView)
        hostingVC.title = "Text to Speech (SwiftUI)"
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Speaking..."
            self.statusLabel.textColor = .systemGreen
            self.speakButton.isEnabled = false
            self.pauseResumeButton.isEnabled = true
            self.pauseResumeButton.setTitle("Pause", for: .normal)
            self.stopButton.isEnabled = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Idle"
            self.statusLabel.textColor = .secondaryLabel
            self.speakButton.isEnabled = true
            self.pauseResumeButton.isEnabled = false
            self.stopButton.isEnabled = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Paused"
            self.statusLabel.textColor = .systemOrange
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Speaking..."
            self.statusLabel.textColor = .systemGreen
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Idle"
            self.statusLabel.textColor = .secondaryLabel
            self.speakButton.isEnabled = true
            self.pauseResumeButton.isEnabled = false
            self.stopButton.isEnabled = false
        }
    }
}
