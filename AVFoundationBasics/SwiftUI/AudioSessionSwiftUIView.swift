import SwiftUI
import AVFoundation

// MARK: - AudioSessionViewModel

@MainActor
final class AudioSessionViewModel: ObservableObject {

    // MARK: - Published
    @Published var categoryDisplay = ""
    @Published var modeDisplay = ""
    @Published var sampleRate = ""
    @Published var ioBufferDuration = ""
    @Published var inputChannels = ""
    @Published var outputChannels = ""
    @Published var outputLatency = ""
    @Published var inputAvailable = ""
    @Published var routeInfo = ""
    @Published var isActive = false
    @Published var selectedCategoryIndex = 1 // soloAmbient default

    let categoryLabels = ["ambient", "soloAmbient", "playback", "record", "play+rec"]
    private let categoryValues: [AVAudioSession.Category] = [
        .ambient, .soloAmbient, .playback, .record, .playAndRecord
    ]

    // MARK: - Init
    init() {
        refreshInfo()
    }

    // MARK: - Refresh

    func refreshInfo() {
        let session = AVAudioSession.sharedInstance()

        func shortName(_ rawValue: String) -> String {
            rawValue.components(separatedBy: ".").last ?? rawValue
        }

        categoryDisplay = shortName(session.category.rawValue)
        modeDisplay = shortName(session.mode.rawValue)
        sampleRate = String(format: "%.0f Hz", session.sampleRate)
        ioBufferDuration = String(format: "%.2f ms", session.ioBufferDuration * 1000)
        inputChannels = "\(session.inputNumberOfChannels)"
        outputChannels = "\(session.outputNumberOfChannels)"
        outputLatency = String(format: "%.2f ms", session.outputLatency * 1000)
        inputAvailable = session.isInputAvailable ? "Yes" : "No"

        let route = session.currentRoute
        var routeLines: [String] = []
        for input in route.inputs {
            let type = shortName(input.portType.rawValue)
            routeLines.append("In: \(input.portName) [\(type)]")
        }
        for output in route.outputs {
            let type = shortName(output.portType.rawValue)
            routeLines.append("Out: \(output.portName) [\(type)]")
        }
        routeInfo = routeLines.isEmpty ? "No active route" : routeLines.joined(separator: "\n")
    }

    // MARK: - Activate / Deactivate

    func activate() {
        let cat = categoryValues[selectedCategoryIndex]
        do {
            try AVAudioSession.sharedInstance().setCategory(cat, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            isActive = true
            refreshInfo()
        } catch {
            print("Activate error: \(error)")
        }
    }

    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            isActive = false
            refreshInfo()
        } catch {
            print("Deactivate error: \(error)")
        }
    }
}

// MARK: - AudioSessionSwiftUIView

struct AudioSessionSwiftUIView: View {
    @StateObject private var vm = AudioSessionViewModel()

    var body: some View {
        List {
            // Current Session section
            Section("Current Session") {
                infoRow("Category", value: vm.categoryDisplay)
                infoRow("Mode", value: vm.modeDisplay)
                infoRow("Sample Rate", value: vm.sampleRate)
                infoRow("IO Buffer Duration", value: vm.ioBufferDuration)
                infoRow("Output Channels", value: vm.outputChannels)
                infoRow("Input Channels", value: vm.inputChannels)
                infoRow("Output Latency", value: vm.outputLatency)
                infoRow("Input Available", value: vm.inputAvailable)
            }

            // Category picker
            Section("Change Category") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Category", selection: $vm.selectedCategoryIndex) {
                        ForEach(0..<vm.categoryLabels.count, id: \.self) { i in
                            Text(vm.categoryLabels[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)

                HStack {
                    Button(action: vm.activate) {
                        Label("Activate", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isActive)

                    Spacer()

                    Button(role: .destructive, action: vm.deactivate) {
                        Label("Deactivate", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!vm.isActive)
                }
                .padding(.vertical, 4)

                HStack {
                    Text("Session active:")
                    Spacer()
                    Text(vm.isActive ? "Yes" : "No")
                        .foregroundStyle(vm.isActive ? .green : .secondary)
                        .fontWeight(.medium)
                }
            }

            // Route info
            Section("Route Info") {
                Text(vm.routeInfo)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // About
            Section("About") {
                Text("AVAudioSession manages your app's audio context — category, mode, and routing. Change the category to control how your audio interacts with the system and other apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Audio Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: vm.refreshInfo) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.system(size: 14, design: .monospaced))
        }
    }
}

#Preview {
    NavigationView { AudioSessionSwiftUIView() }
}
