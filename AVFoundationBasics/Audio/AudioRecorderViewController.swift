import UIKit
import AVFoundation
import SwiftUI

// MARK: - AudioRecorderViewController

class AudioRecorderViewController: UIViewController {

    // MARK: - AVFoundation
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    private var hasRecording = false

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
    }

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let statusLabel = UILabel()
    private let recordButton = UIButton(type: .custom)
    private let timerLabel = UILabel()
    private let levelMeter = UIProgressView(progressViewStyle: .default)
    private let levelLabel = UILabel()
    private let playStopButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio Recorder"
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupScrollView()
        setupStack()
        requestMicPermission()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllTimers()
        audioRecorder?.stop()
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

        // Status
        stackView.addArrangedSubview(makeSectionLabel("Status"))
        statusLabel.text = "Ready to record"
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        stackView.addArrangedSubview(statusLabel)

        // Record button
        stackView.addArrangedSubview(makeSectionLabel("Record"))
        configureRecordButton()
        let recordContainer = UIView()
        recordContainer.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: recordContainer.centerXAnchor),
            recordButton.topAnchor.constraint(equalTo: recordContainer.topAnchor),
            recordButton.bottomAnchor.constraint(equalTo: recordContainer.bottomAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        stackView.addArrangedSubview(recordContainer)

        // Timer
        timerLabel.text = "0:00.0"
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .thin)
        timerLabel.textAlignment = .center
        timerLabel.textColor = .label
        stackView.addArrangedSubview(timerLabel)

        // Level meter
        stackView.addArrangedSubview(makeSectionLabel("Input Level"))
        levelLabel.text = "Level: 0%"
        levelLabel.font = UIFont.systemFont(ofSize: 13)
        levelLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(levelLabel)

        levelMeter.progress = 0
        levelMeter.progressTintColor = .systemGreen
        stackView.addArrangedSubview(levelMeter)

        // Playback
        stackView.addArrangedSubview(makeSectionLabel("Playback"))
        playStopButton.setTitle("Play Recording", for: .normal)
        playStopButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        playStopButton.isEnabled = false
        playStopButton.addTarget(self, action: #selector(playStopTapped), for: .touchUpInside)
        stackView.addArrangedSubview(playStopButton)

        // Delete
        stackView.addArrangedSubview(makeSectionLabel("Manage"))
        deleteButton.setTitle("Delete Recording", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        deleteButton.isEnabled = false
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        stackView.addArrangedSubview(deleteButton)

        // Info
        stackView.addArrangedSubview(makeSectionLabel("About"))
        let infoLabel = UILabel()
        infoLabel.text = "AVAudioRecorder records audio to a file. Tap the red button to start recording. The level meter shows real-time input power. Play back your recording immediately without leaving the screen."
        infoLabel.font = UIFont.systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stackView.addArrangedSubview(infoLabel)
    }

    private func configureRecordButton() {
        recordButton.backgroundColor = .systemRed
        recordButton.layer.cornerRadius = 40
        recordButton.layer.masksToBounds = true
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        updateRecordButtonAppearance(isRecording: false)
    }

    private func updateRecordButtonAppearance(isRecording: Bool) {
        UIView.animate(withDuration: 0.2) {
            if isRecording {
                self.recordButton.layer.cornerRadius = 12
                self.recordButton.backgroundColor = .systemRed
            } else {
                self.recordButton.layer.cornerRadius = 40
                self.recordButton.backgroundColor = .systemRed
            }
        }
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }

    // MARK: - Permissions

    private func requestMicPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.statusLabel.text = "Microphone access denied. Please enable in Settings."
                    self?.recordButton.isEnabled = false
                }
            }
        }
    }

    // MARK: - Recording

    @objc private func recordTapped() {
        if audioRecorder?.isRecording == true {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        // Stop playback if active
        audioPlayer?.stop()
        audioPlayer = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            statusLabel.text = "Session error: \(error.localizedDescription)"
            return
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            recordingDuration = 0
            statusLabel.text = "Recording..."
            updateRecordButtonAppearance(isRecording: true)
            startRecordingTimer()
            startLevelTimer()
            playStopButton.isEnabled = false
            deleteButton.isEnabled = false
        } catch {
            statusLabel.text = "Recorder error: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        stopAllTimers()
        updateRecordButtonAppearance(isRecording: false)
        levelMeter.progress = 0
        levelLabel.text = "Level: 0%"
        hasRecording = true
        let duration = recordingDuration
        statusLabel.text = String(format: "Recorded (%.1fs)", duration)
        playStopButton.isEnabled = true
        deleteButton.isEnabled = true

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print("Session switch error: \(error)")
        }
    }

    // MARK: - Playback

    @objc private func playStopTapped() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            audioPlayer = nil
            playStopButton.setTitle("Play Recording", for: .normal)
            statusLabel.text = hasRecording ? String(format: "Recorded (%.1fs)", recordingDuration) : "Ready to record"
        } else {
            guard FileManager.default.fileExists(atPath: recordingURL.path) else { return }

            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)

                audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                playStopButton.setTitle("Stop Playback", for: .normal)
                statusLabel.text = "Playing..."
            } catch {
                statusLabel.text = "Playback error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Delete

    @objc private func deleteTapped() {
        audioPlayer?.stop()
        audioPlayer = nil
        do {
            try FileManager.default.removeItem(at: recordingURL)
        } catch {
            print("Delete error: \(error)")
        }
        hasRecording = false
        recordingDuration = 0
        timerLabel.text = "0:00.0"
        statusLabel.text = "Ready to record"
        playStopButton.setTitle("Play Recording", for: .normal)
        playStopButton.isEnabled = false
        deleteButton.isEnabled = false
    }

    // MARK: - Timers

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            let total = self.recordingDuration
            let minutes = Int(total) / 60
            let seconds = Int(total) % 60
            let tenths = Int((total - Double(Int(total))) * 10)
            self.timerLabel.text = String(format: "%d:%02d.%d", minutes, seconds, tenths)
        }
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let recorder = self?.audioRecorder, recorder.isRecording else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            // Normalize from ~-60dB to 0dB → 0.0 to 1.0
            let normalized = max(0, (power + 60) / 60)
            self?.levelMeter.progress = Float(normalized)
            self?.levelLabel.text = String(format: "Level: %d%%", Int(normalized * 100))
        }
    }

    private func stopAllTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    // MARK: - Bar Button Actions

    @objc private func showCode() {
        let snippet = """
import AVFoundation

// Setup session for recording
let session = AVAudioSession.sharedInstance()
try session.setCategory(.record, mode: .default)
try session.setActive(true)

// Configure recorder settings (AAC, 44100Hz, mono)
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 44100,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]

// Create recorder pointing to a file URL
let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("recording.m4a")
let recorder = try AVAudioRecorder(url: url, settings: settings)
recorder.delegate = self
recorder.isMeteringEnabled = true  // enable level metering
recorder.record()

// Read level meter
recorder.updateMeters()
let power = recorder.averagePower(forChannel: 0)  // dBFS, typically -60...0
let normalized = max(0, (power + 60) / 60)

// Stop recording
recorder.stop()

// Switch session to playback and play back recording
try session.setCategory(.playback, mode: .default)
let player = try AVAudioPlayer(contentsOf: url)
player.delegate = self
player.play()
"""
        CodeSheetViewController.showCodeSheet(from: self, code: snippet)
    }

    @objc private func showSwiftUI() {
        let swiftUIView = AudioRecorderSwiftUIView()
        let hostingVC = UIHostingController(rootView: swiftUIView)
        hostingVC.title = "Audio Recorder (SwiftUI)"
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            statusLabel.text = "Recording failed"
            hasRecording = false
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        statusLabel.text = "Encode error: \(error?.localizedDescription ?? "unknown")"
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        playStopButton.setTitle("Play Recording", for: .normal)
        statusLabel.text = String(format: "Recorded (%.1fs)", recordingDuration)
    }
}
