import SwiftUI
import AVFoundation

// MARK: - AssetInspectorViewModel

@MainActor
final class AssetInspectorViewModel: ObservableObject {

    // MARK: - Published
    @Published var isLoading = false
    @Published var resultText = "Tap \"Inspect Asset\" to load metadata..."
    @Published var selectedIndex = 0

    let videoURLStrings = [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    ]

    let videoLabels = ["Big Buck Bunny", "Elephants Dream", "For Bigger Blazes"]

    // MARK: - Private
    private var currentTask: Task<Void, Never>?

    // MARK: - Inspect

    func inspect() {
        currentTask?.cancel()
        guard let url = URL(string: videoURLStrings[selectedIndex]) else { return }
        isLoading = true
        resultText = "Loading asset metadata..."

        let label = videoLabels[selectedIndex]
        currentTask = Task {
            do {
                let text = try await loadAssetInfo(url: url, label: label)
                if !Task.isCancelled {
                    self.resultText = text
                    self.isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    self.resultText = (error is CancellationError)
                        ? "Cancelled"
                        : "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func cancelInspection() {
        currentTask?.cancel()
        isLoading = false
        resultText = "Inspection cancelled."
    }

    // MARK: - Asset Loading

    private func loadAssetInfo(url: URL, label: String) async throws -> String {
        let asset = AVURLAsset(url: url)

        let duration = try await asset.load(.duration)
        let isPlayable = try await asset.load(.isPlayable)
        let tracks = try await asset.load(.tracks)

        var lines: [String] = []
        lines.append("Asset: \(label)")
        lines.append("File:  \(url.lastPathComponent)")
        lines.append("")
        lines.append("Duration:    \(formatDuration(duration))")
        lines.append("Is Playable: \(isPlayable ? "Yes" : "No")")
        lines.append("")

        let videoTracks = tracks.filter { $0.mediaType == .video }
        lines.append("Video Tracks: \(videoTracks.count)")
        if let vt = videoTracks.first {
            let size = try await vt.load(.naturalSize)
            let fps = try await vt.load(.nominalFrameRate)
            let kbps = try await vt.load(.estimatedDataRate)
            lines.append("  Size:      \(Int(size.width))×\(Int(size.height))")
            lines.append("  Frame Rate: \(String(format: "%.2f fps", fps))")
            lines.append(String(format: "  Data Rate:  %.0f kbps", kbps / 1000))
        }
        lines.append("")

        let audioTracks = tracks.filter { $0.mediaType == .audio }
        lines.append("Audio Tracks: \(audioTracks.count)")
        if let at = audioTracks.first {
            let kbps = try await at.load(.estimatedDataRate)
            lines.append(String(format: "  Data Rate:  %.0f kbps", kbps / 1000))
        }

        return lines.joined(separator: "\n")
    }

    private func formatDuration(_ time: CMTime) -> String {
        guard time.isValid && !time.isIndefinite else { return "Unknown" }
        let total = Int(CMTimeGetSeconds(time))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}

// MARK: - AssetInspectorSwiftUIView

struct AssetInspectorSwiftUIView: View {
    @StateObject private var vm = AssetInspectorViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title
                Text("Asset Inspector")
                    .font(.title2.bold())
                    .padding(.top, 4)

                // URL selection
                GroupBox(label: sectionLabel("Select Asset")) {
                    Picker("Asset", selection: $vm.selectedIndex) {
                        ForEach(0..<vm.videoLabels.count, id: \.self) { i in
                            Text(vm.videoLabels[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)

                    Text(vm.videoURLStrings[vm.selectedIndex])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                // Controls
                GroupBox(label: sectionLabel("Controls")) {
                    HStack(spacing: 16) {
                        Button(action: vm.inspect) {
                            Label("Inspect Asset", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isLoading)

                        if vm.isLoading {
                            Button(action: vm.cancelInspection) {
                                Label("Cancel", systemImage: "xmark.circle")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 4)

                    if vm.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading metadata...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }

                // Results
                GroupBox(label: sectionLabel("Results")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(vm.resultText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(vm.isLoading ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 4)
                }

                // About
                GroupBox(label: sectionLabel("About")) {
                    Text("AVAsset loads media metadata asynchronously using the modern async/await load(_:) API (iOS 15+). Properties like duration, tracks, naturalSize, and nominalFrameRate are fetched on demand without blocking the main thread.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Asset Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.blue)
    }
}

#Preview {
    NavigationView { AssetInspectorSwiftUIView() }
}
