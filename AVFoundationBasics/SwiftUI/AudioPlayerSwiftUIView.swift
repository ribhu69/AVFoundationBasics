import SwiftUI
import AVFoundation
import Combine

// MARK: - AudioPlayerViewModel

@MainActor
final class AudioPlayerViewModel: ObservableObject {

    // MARK: - Published
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 1.0
    @Published var rate: Float = 1.0
    @Published var isLooping = false
    @Published var selectedFrequency: Double = 440.0

    // MARK: - Private
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?

    // MARK: - Init

    init() {
        setupSession()
        loadTone(frequency: selectedFrequency)
        startTimer()
    }

    // MARK: - Session

    private func setupSession() {
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

    func loadTone(frequency: Double) {
        let wasPlaying = audioPlayer?.isPlaying ?? false
        audioPlayer?.stop()
        let toneData = generateToneData(frequency: frequency, duration: 3.0)
        do {
            audioPlayer = try AVAudioPlayer(data: toneData)
            audioPlayer?.enableRate = true
            audioPlayer?.volume = volume
            audioPlayer?.rate = rate
            audioPlayer?.numberOfLoops = isLooping ? -1 : 0
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            if wasPlaying {
                audioPlayer?.play()
                isPlaying = true
            }
        } catch {
            print("Player error: \(error)")
        }
    }

    // MARK: - Controls

    func playPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
    }

    func setVolume(_ v: Float) {
        volume = v
        audioPlayer?.volume = v
    }

    func setRate(_ r: Float) {
        rate = r
        audioPlayer?.rate = r
    }

    func setLooping(_ loop: Bool) {
        isLooping = loop
        audioPlayer?.numberOfLoops = loop ? -1 : 0
    }

    func selectFrequency(_ freq: Double) {
        selectedFrequency = freq
        loadTone(frequency: freq)
    }

    // MARK: - Timer

    private func startTimer() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying && self.isPlaying {
                    self.isPlaying = false
                    self.currentTime = 0
                }
            }
    }

    // MARK: - Helpers

    func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - AudioPlayerSwiftUIView

struct AudioPlayerSwiftUIView: View {
    @StateObject private var vm = AudioPlayerViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title
                Text("Audio Player")
                    .font(.title2.bold())
                    .padding(.top, 4)

                // Frequency picker
                GroupBox(label: sectionLabel("Tone Selection")) {
                    Picker("Frequency", selection: Binding(
                        get: { vm.selectedFrequency },
                        set: { vm.selectFrequency($0) }
                    )) {
                        Text("A4 — 440 Hz").tag(440.0)
                        Text("A5 — 880 Hz").tag(880.0)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)
                }

                // Playback controls
                GroupBox(label: sectionLabel("Playback")) {
                    HStack(spacing: 16) {
                        Button(action: vm.playPause) {
                            Label(vm.isPlaying ? "Pause" : "Play",
                                  systemImage: vm.isPlaying ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: vm.stop) {
                            Label("Stop", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)

                    // Progress
                    VStack(spacing: 4) {
                        ProgressView(
                            value: vm.duration > 0 ? vm.currentTime : 0,
                            total: vm.duration > 0 ? vm.duration : 1
                        )
                        HStack {
                            Text(vm.formatTime(vm.currentTime))
                            Spacer()
                            Text(vm.formatTime(vm.duration))
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }

                // Volume
                GroupBox(label: sectionLabel("Volume")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Volume: %.2f", vm.volume))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: Binding(
                            get: { Double(vm.volume) },
                            set: { vm.setVolume(Float($0)) }
                        ), in: 0...1)
                    }
                    .padding(.top, 4)
                }

                // Rate
                GroupBox(label: sectionLabel("Rate")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Rate: %.2fx", vm.rate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: Binding(
                            get: { Double(vm.rate) },
                            set: { vm.setRate(Float($0)) }
                        ), in: 0.5...2.0)
                    }
                    .padding(.top, 4)
                }

                // Loop
                GroupBox(label: sectionLabel("Options")) {
                    Toggle("Loop Playback", isOn: Binding(
                        get: { vm.isLooping },
                        set: { vm.setLooping($0) }
                    ))
                    .padding(.top, 4)
                }

                // Info
                GroupBox(label: sectionLabel("About")) {
                    Text("AVAudioPlayer plays audio data or files with full playback control including volume, rate, and looping. Tones are generated as in-memory WAV PCM data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Audio Player")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationView { AudioPlayerSwiftUIView() }
}
