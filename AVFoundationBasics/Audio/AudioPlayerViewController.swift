import UIKit
import AVFoundation
import SwiftUI

// MARK: - AudioPlayerViewController

class AudioPlayerViewController: UIViewController {

    // MARK: - AVFoundation
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let frequencySegment = UISegmentedControl(items: ["A4 — 440 Hz", "A5 — 880 Hz"])
    private let playPauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let timeLabel = UILabel()
    private let volumeSlider = UISlider()
    private let volumeLabel = UILabel()
    private let rateSlider = UISlider()
    private let rateLabel = UILabel()
    private let loopSwitch = UISwitch()
    private let loopLabel = UILabel()
    private let statusLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio Player"
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupScrollView()
        setupStack()
        setupAudioSession()
        loadTone(frequency: 440)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopProgressTimer()
        audioPlayer?.stop()
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
        stackView.spacing = 16
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

        // Section header
        stackView.addArrangedSubview(makeSectionLabel("Tone Selection"))

        // Frequency picker
        frequencySegment.selectedSegmentIndex = 0
        frequencySegment.addTarget(self, action: #selector(frequencyChanged), for: .valueChanged)
        stackView.addArrangedSubview(frequencySegment)

        // Playback controls
        stackView.addArrangedSubview(makeSectionLabel("Playback Controls"))

        playPauseButton.setTitle("Play", for: .normal)
        playPauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        stopButton.setTitle("Stop", for: .normal)
        stopButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [playPauseButton, stopButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 12
        stackView.addArrangedSubview(buttonRow)

        // Status
        statusLabel.text = "Stopped"
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(statusLabel)

        // Progress
        stackView.addArrangedSubview(makeSectionLabel("Progress"))
        progressView.progress = 0
        stackView.addArrangedSubview(progressView)

        timeLabel.text = "0:00 / 0:00"
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(timeLabel)

        // Volume
        stackView.addArrangedSubview(makeSectionLabel("Volume"))
        volumeLabel.text = "Volume: 1.00"
        volumeLabel.font = UIFont.systemFont(ofSize: 13)
        volumeLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(volumeLabel)

        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = 1
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        stackView.addArrangedSubview(volumeSlider)

        // Rate
        stackView.addArrangedSubview(makeSectionLabel("Rate"))
        rateLabel.text = "Rate: 1.00x"
        rateLabel.font = UIFont.systemFont(ofSize: 13)
        rateLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(rateLabel)

        rateSlider.minimumValue = 0.5
        rateSlider.maximumValue = 2.0
        rateSlider.value = 1.0
        rateSlider.addTarget(self, action: #selector(rateChanged), for: .valueChanged)
        stackView.addArrangedSubview(rateSlider)

        // Loop
        stackView.addArrangedSubview(makeSectionLabel("Options"))
        let loopRow = UIStackView(arrangedSubviews: [loopLabel, loopSwitch])
        loopRow.axis = .horizontal
        loopRow.spacing = 12
        loopRow.alignment = .center
        loopLabel.text = "Loop"
        loopLabel.font = UIFont.systemFont(ofSize: 16)
        loopSwitch.addTarget(self, action: #selector(loopChanged), for: .valueChanged)
        stackView.addArrangedSubview(loopRow)

        // Info
        stackView.addArrangedSubview(makeSectionLabel("About"))
        let infoLabel = UILabel()
        infoLabel.text = "AVAudioPlayer plays audio data or files in memory with full control over volume, rate, and looping. Tones are generated as in-memory WAV data without writing to disk."
        infoLabel.font = UIFont.systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stackView.addArrangedSubview(infoLabel)
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemBlue
        label.textTransform(uppercased: true)
        return label
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession error: \(error)")
        }
    }

    // MARK: - Tone Generation

    private func generateToneData(frequency: Double, duration: Double) -> Data {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)
        var data = Data()
        func le<T: FixedWidthInteger>(_ v: T) -> Data {
            var x = v.littleEndian
            return Swift.withUnsafeBytes(of: &x) { Data($0) }
        }
        data += "RIFF".data(using: .ascii)!
        data += le(Int32(36 + frameCount * 2))
        data += "WAVE".data(using: .ascii)!
        data += "fmt ".data(using: .ascii)!
        data += le(Int32(16))
        data += le(Int16(1))
        data += le(Int16(1))
        data += le(Int32(sampleRate))
        data += le(Int32(Int(sampleRate) * 2))
        data += le(Int16(2))
        data += le(Int16(16))
        data += "data".data(using: .ascii)!
        data += le(Int32(frameCount * 2))
        for i in 0..<frameCount {
            data += le(Int16(32000 * sin(2 * Double.pi * frequency * Double(i) / sampleRate)))
        }
        return data
    }

    private func loadTone(frequency: Double) {
        let wasPlaying = audioPlayer?.isPlaying ?? false
        audioPlayer?.stop()
        stopProgressTimer()

        let toneData = generateToneData(frequency: frequency, duration: 3.0)
        do {
            audioPlayer = try AVAudioPlayer(data: toneData)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.volume = volumeSlider.value
            audioPlayer?.rate = rateSlider.value
            audioPlayer?.numberOfLoops = loopSwitch.isOn ? -1 : 0
            audioPlayer?.prepareToPlay()
            updateTimeLabel()
            if wasPlaying {
                audioPlayer?.play()
                startProgressTimer()
                updatePlayPauseButton()
            }
        } catch {
            statusLabel.text = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }
        let duration = player.duration
        if duration > 0 {
            progressView.progress = Float(player.currentTime / duration)
        }
        updateTimeLabel()
    }

    private func updateTimeLabel() {
        guard let player = audioPlayer else {
            timeLabel.text = "0:00 / 0:00"
            return
        }
        timeLabel.text = "\(formatTime(player.currentTime)) / \(formatTime(player.duration))"
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func updatePlayPauseButton() {
        let isPlaying = audioPlayer?.isPlaying ?? false
        playPauseButton.setTitle(isPlaying ? "Pause" : "Play", for: .normal)
        statusLabel.text = isPlaying ? "Playing" : "Paused"
    }

    // MARK: - Actions

    @objc private func frequencyChanged() {
        let freq: Double = frequencySegment.selectedSegmentIndex == 0 ? 440 : 880
        loadTone(frequency: freq)
    }

    @objc private func playPauseTapped() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            stopProgressTimer()
            statusLabel.text = "Paused"
        } else {
            player.play()
            startProgressTimer()
            statusLabel.text = "Playing"
        }
        updatePlayPauseButton()
    }

    @objc private func stopTapped() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        stopProgressTimer()
        progressView.progress = 0
        updateTimeLabel()
        playPauseButton.setTitle("Play", for: .normal)
        statusLabel.text = "Stopped"
    }

    @objc private func volumeChanged() {
        audioPlayer?.volume = volumeSlider.value
        volumeLabel.text = String(format: "Volume: %.2f", volumeSlider.value)
    }

    @objc private func rateChanged() {
        audioPlayer?.rate = rateSlider.value
        rateLabel.text = String(format: "Rate: %.2fx", rateSlider.value)
    }

    @objc private func loopChanged() {
        audioPlayer?.numberOfLoops = loopSwitch.isOn ? -1 : 0
    }

    @objc private func showCode() {
        let snippet = """
import AVFoundation

// Configure audio session
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default)
try session.setActive(true)

// Generate WAV data in memory
func generateToneData(frequency: Double, duration: Double) -> Data {
    let sampleRate: Double = 44100
    let frameCount = Int(sampleRate * duration)
    var data = Data()
    // ... WAV header + PCM samples ...
    for i in 0..<frameCount {
        let sample = Int16(32000 * sin(2 * .pi * frequency * Double(i) / sampleRate))
        // append little-endian sample bytes
    }
    return data
}

// Initialize AVAudioPlayer from Data
let toneData = generateToneData(frequency: 440, duration: 3.0)
let player = try AVAudioPlayer(data: toneData)
player.enableRate = true
player.volume = 1.0
player.rate = 1.0
player.numberOfLoops = 0  // -1 = infinite loop
player.prepareToPlay()
player.play()

// Pause, stop, seek
player.pause()
player.stop()
player.currentTime = 0.0

// Monitor progress
let elapsed = player.currentTime
let total = player.duration
"""
        CodeSheetViewController.showCodeSheet(from: self, code: snippet)
    }

    @objc private func showSwiftUI() {
        let swiftUIView = AudioPlayerSwiftUIView()
        let hostingVC = UIHostingController(rootView: swiftUIView)
        hostingVC.title = "Audio Player (SwiftUI)"
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopProgressTimer()
        progressView.progress = 0
        updateTimeLabel()
        playPauseButton.setTitle("Play", for: .normal)
        statusLabel.text = "Finished"
    }
}

// MARK: - UILabel helper

private extension UILabel {
    func textTransform(uppercased: Bool) {
        if uppercased, let t = text {
            text = t.uppercased()
        }
    }
}
