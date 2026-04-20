import SwiftUI
import AVFoundation

// MARK: - TTSViewModel

@MainActor
final class TTSViewModel: NSObject, ObservableObject {

    // MARK: - Published
    @Published var inputText = "Welcome to AVFoundation. AVSpeechSynthesizer converts text to speech with control over rate, pitch, and language."
    @Published var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published var pitch: Float = 1.0
    @Published var volume: Float = 1.0
    @Published var selectedLanguageIndex = 0
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var statusText = "Idle"

    let languages = [("English", "en-US"), ("Spanish", "es-ES"), ("French", "fr-FR")]

    // MARK: - Private
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init
    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Controls

    func speak() {
        synthesizer.stopSpeaking(at: .immediate)
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: languages[selectedLanguageIndex].1)
        synthesizer.speak(utterance)
    }

    func pauseOrResume() {
        if isPaused {
            synthesizer.continueSpeaking()
        } else {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
        statusText = "Speaking..."
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        statusText = "Idle"
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPaused = true
        statusText = "Paused"
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPaused = false
        statusText = "Speaking..."
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        statusText = "Idle"
    }
}

// MARK: - TextToSpeechSwiftUIView

struct TextToSpeechSwiftUIView: View {
    @StateObject private var vm = TTSViewModel()

    var statusColor: Color {
        if vm.isPaused { return .orange }
        if vm.isSpeaking { return .green }
        return .secondary
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title
                Text("Text to Speech")
                    .font(.title2.bold())
                    .padding(.top, 4)

                // Text input
                GroupBox(label: sectionLabel("Text to Speak")) {
                    TextEditor(text: $vm.inputText)
                        .frame(minHeight: 100)
                        .font(.system(size: 15))
                        .padding(.top, 4)
                }

                // Parameters
                GroupBox(label: sectionLabel("Speech Parameters")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Rate
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "Rate: %.2f", vm.rate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $vm.rate, in: 0.1...0.9)
                        }

                        Divider()

                        // Pitch
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "Pitch: %.2f", vm.pitch))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $vm.pitch, in: 0.5...2.0)
                        }

                        Divider()

                        // Volume
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "Volume: %.2f", vm.volume))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $vm.volume, in: 0.0...1.0)
                        }
                    }
                    .padding(.top, 4)
                }

                // Language
                GroupBox(label: sectionLabel("Language")) {
                    Picker("Language", selection: $vm.selectedLanguageIndex) {
                        ForEach(0..<vm.languages.count, id: \.self) { i in
                            Text(vm.languages[i].0).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)
                }

                // Controls
                GroupBox(label: sectionLabel("Controls")) {
                    HStack(spacing: 10) {
                        Button(action: vm.speak) {
                            Label("Speak", systemImage: "mic.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isSpeaking)

                        Button(action: vm.pauseOrResume) {
                            Label(vm.isPaused ? "Resume" : "Pause",
                                  systemImage: vm.isPaused ? "play.fill" : "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!vm.isSpeaking)

                        Button(action: vm.stop) {
                            Label("Stop", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!vm.isSpeaking)
                    }
                    .padding(.top, 4)
                }

                // Status badge
                GroupBox(label: sectionLabel("Status")) {
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                        Text(vm.statusText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(statusColor)
                        Spacer()
                    }
                    .padding(.top, 4)
                }

                // Info
                GroupBox(label: sectionLabel("About")) {
                    Text("AVSpeechSynthesizer reads text aloud using synthesized voices. AVSpeechUtterance encapsulates the text plus rate, pitch, and volume. Implement AVSpeechSynthesizerDelegate to track speech lifecycle events.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Text to Speech")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationView { TextToSpeechSwiftUIView() }
}
