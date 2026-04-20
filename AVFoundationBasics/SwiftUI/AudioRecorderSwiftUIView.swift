import SwiftUI
import AVFoundation
import Combine

// MARK: - AudioRecorderViewModel

@MainActor
final class AudioRecorderViewModel: NSObject, ObservableObject {

    // MARK: - Published
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var isPlaying = false
    @Published var statusText = "Ready to record"
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0

    // MARK: - Private
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: AnyCancellable?
    private var levelTimer: AnyCancellable?

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("swiftui_recording.m4a")
    }

    // MARK: - Init
    override init() {
        super.init()
        requestPermission()
    }

    // MARK: - Permission
    private func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.statusText = "Microphone access denied. Enable in Settings."
                }
            }
        }
    }

    // MARK: - Record

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            statusText = "Session error: \(error.localizedDescription)"
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
            isRecording = true
            recordingDuration = 0
            statusText = "Recording..."

            // Duration timer
            recordingTimer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.recordingDuration += 0.1
                }

            // Level timer
            levelTimer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let recorder = self?.audioRecorder, recorder.isRecording else { return }
                    recorder.updateMeters()
                    let power = recorder.averagePower(forChannel: 0)
                    self?.audioLevel = Float(max(0, (power + 60) / 60))
                }
        } catch {
            statusText = "Recorder error: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        stopTimers()
        isRecording = false
        audioLevel = 0
        hasRecording = true
        statusText = String(format: "Recorded (%.1fs)", recordingDuration)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print("Session switch error: \(error)")
        }
    }

    // MARK: - Playback

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying = false
            statusText = String(format: "Recorded (%.1fs)", recordingDuration)
        } else {
            guard FileManager.default.fileExists(atPath: recordingURL.path) else { return }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                isPlaying = true
                statusText = "Playing..."
            } catch {
                statusText = "Playback error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Delete

    func deleteRecording() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? FileManager.default.removeItem(at: recordingURL)
        isPlaying = false
        hasRecording = false
        recordingDuration = 0
        audioLevel = 0
        statusText = "Ready to record"
    }

    // MARK: - Helpers

    private func stopTimers() {
        recordingTimer?.cancel()
        recordingTimer = nil
        levelTimer?.cancel()
        levelTimer = nil
    }

    func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        let t = Int((seconds - Double(Int(seconds))) * 10)
        return String(format: "%d:%02d.%d", m, s, t)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            statusText = "Recording failed"
            hasRecording = false
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        statusText = String(format: "Recorded (%.1fs)", recordingDuration)
    }
}

// MARK: - AudioRecorderSwiftUIView

struct AudioRecorderSwiftUIView: View {
    @StateObject private var vm = AudioRecorderViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title
                Text("Audio Recorder")
                    .font(.title2.bold())
                    .padding(.top, 4)

                // Status
                GroupBox(label: sectionLabel("Status")) {
                    Text(vm.statusText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(vm.isRecording ? .red : (vm.isPlaying ? .green : .secondary))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }

                // Record button
                GroupBox(label: sectionLabel("Record")) {
                    VStack(spacing: 12) {
                        Button(action: vm.toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(vm.isRecording ? Color.red : Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                if vm.isRecording {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Text(vm.formatDuration(vm.recordingDuration))
                            .font(.system(size: 28, weight: .thin, design: .monospaced))
                    }
                    .padding(.top, 4)
                }

                // Level meter
                GroupBox(label: sectionLabel("Input Level")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Level: %d%%", Int(vm.audioLevel * 100)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: Double(vm.audioLevel), total: 1.0)
                            .tint(.green)
                    }
                    .padding(.top, 4)
                }

                // Playback
                GroupBox(label: sectionLabel("Playback")) {
                    HStack(spacing: 16) {
                        Button(action: vm.togglePlayback) {
                            Label(vm.isPlaying ? "Stop" : "Play Recording",
                                  systemImage: vm.isPlaying ? "stop.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!vm.hasRecording)
                    }
                    .padding(.top, 4)
                }

                // Delete
                GroupBox(label: sectionLabel("Manage")) {
                    Button(role: .destructive, action: vm.deleteRecording) {
                        Label("Delete Recording", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!vm.hasRecording)
                    .padding(.top, 4)
                }

                // Info
                GroupBox(label: sectionLabel("About")) {
                    Text("AVAudioRecorder records audio to a file using configurable format settings. Enable metering to monitor real-time input levels. Switch the AVAudioSession category between .record and .playback as needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Audio Recorder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationView { AudioRecorderSwiftUIView() }
}
