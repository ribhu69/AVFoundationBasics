import UIKit
import AVFoundation
import SwiftUI

// MARK: - AssetInspectorViewController

class AssetInspectorViewController: UIViewController {

    // MARK: - Data
    private let videoURLStrings: [String] = [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    ]

    private let videoLabels = ["Big Buck Bunny", "Elephants Dream", "For Bigger Blazes"]

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private var urlSegment: UISegmentedControl!
    private let inspectButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let resultTextView = UITextView()

    // MARK: - Task tracking
    private var currentTask: Task<Void, Never>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Asset Inspector"
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupScrollView()
        setupStack()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentTask?.cancel()
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

        // URL selection
        stackView.addArrangedSubview(makeSectionLabel("Select Asset"))
        urlSegment = UISegmentedControl(items: videoLabels)
        urlSegment.selectedSegmentIndex = 0
        stackView.addArrangedSubview(urlSegment)

        // Inspect button + activity indicator
        inspectButton.setTitle("Inspect Asset", for: .normal)
        inspectButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        inspectButton.addTarget(self, action: #selector(inspectTapped), for: .touchUpInside)

        activityIndicator.hidesWhenStopped = true

        let controlRow = UIStackView(arrangedSubviews: [inspectButton, activityIndicator])
        controlRow.axis = .horizontal
        controlRow.spacing = 12
        controlRow.alignment = .center
        stackView.addArrangedSubview(controlRow)

        // Result text view
        stackView.addArrangedSubview(makeSectionLabel("Results"))
        resultTextView.isEditable = false
        resultTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        resultTextView.backgroundColor = UIColor.systemGray6
        resultTextView.layer.cornerRadius = 8
        resultTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        resultTextView.text = "Tap \"Inspect Asset\" to load metadata..."
        resultTextView.textColor = .secondaryLabel
        resultTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        stackView.addArrangedSubview(resultTextView)

        // Info
        stackView.addArrangedSubview(makeSectionLabel("About"))
        let infoLabel = UILabel()
        infoLabel.text = "AVAsset provides async metadata loading via the modern load(_:) API introduced in iOS 15. Properties are loaded on demand rather than blocking the main thread."
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

    // MARK: - Inspect Action

    @objc private func inspectTapped() {
        currentTask?.cancel()
        let index = urlSegment.selectedSegmentIndex
        guard let url = URL(string: videoURLStrings[index]) else { return }

        inspectButton.isEnabled = false
        activityIndicator.startAnimating()
        resultTextView.text = "Loading asset metadata..."
        resultTextView.textColor = .secondaryLabel

        currentTask = Task {
            do {
                let text = try await loadAssetInfo(url: url, label: videoLabels[index])
                await MainActor.run {
                    self.resultTextView.text = text
                    self.resultTextView.textColor = .label
                    self.activityIndicator.stopAnimating()
                    self.inspectButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    if (error as? CancellationError) != nil { return }
                    self.resultTextView.text = "Error: \(error.localizedDescription)"
                    self.resultTextView.textColor = .systemRed
                    self.activityIndicator.stopAnimating()
                    self.inspectButton.isEnabled = true
                }
            }
        }
    }

    private func loadAssetInfo(url: URL, label: String) async throws -> String {
        let asset = AVURLAsset(url: url)

        // Load duration and playability
        let duration = try await asset.load(.duration)
        let isPlayable = try await asset.load(.isPlayable)
        let tracks = try await asset.load(.tracks)

        var lines: [String] = []
        lines.append("Asset: \(label)")
        lines.append("URL: \(url.lastPathComponent)")
        lines.append("")
        lines.append("Duration:    \(formatDuration(duration))")
        lines.append("Is Playable: \(isPlayable ? "Yes" : "No")")
        lines.append("")

        // Video tracks
        let videoTracks = tracks.filter { $0.mediaType == .video }
        lines.append("Video Tracks: \(videoTracks.count)")
        if let firstVideo = videoTracks.first {
            let naturalSize = try await firstVideo.load(.naturalSize)
            let frameRate = try await firstVideo.load(.nominalFrameRate)
            let dataRate = try await firstVideo.load(.estimatedDataRate)
            lines.append("  Natural Size:  \(Int(naturalSize.width))×\(Int(naturalSize.height))")
            lines.append("  Frame Rate:    \(String(format: "%.2f", frameRate)) fps")
            lines.append(String(format: "  Data Rate:     %.0f kbps", dataRate / 1000))
        }
        lines.append("")

        // Audio tracks
        let audioTracks = tracks.filter { $0.mediaType == .audio }
        lines.append("Audio Tracks: \(audioTracks.count)")
        if let firstAudio = audioTracks.first {
            let dataRate = try await firstAudio.load(.estimatedDataRate)
            lines.append(String(format: "  Data Rate:     %.0f kbps", dataRate / 1000))
        }

        return lines.joined(separator: "\n")
    }

    private func formatDuration(_ time: CMTime) -> String {
        guard time.isValid && !time.isIndefinite else { return "Unknown" }
        let totalSeconds = Int(CMTimeGetSeconds(time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Bar Button Actions

    @objc private func showCode() {
        let snippet = """
import AVFoundation

// Create asset from URL (local or remote)
let url = URL(string: "https://example.com/video.mp4")!
let asset = AVURLAsset(url: url)

// Load properties asynchronously (iOS 15+ async API)
let duration = try await asset.load(.duration)
let isPlayable = try await asset.load(.isPlayable)
let tracks = try await asset.load(.tracks)

// Format duration
let seconds = CMTimeGetSeconds(duration)

// Filter by media type
let videoTracks = tracks.filter { $0.mediaType == .video }
let audioTracks = tracks.filter { $0.mediaType == .audio }

// Load track-level properties
if let videoTrack = videoTracks.first {
    let size = try await videoTrack.load(.naturalSize)
    let fps  = try await videoTrack.load(.nominalFrameRate)
    let kbps = try await videoTrack.load(.estimatedDataRate)
    print("Size: \\(size.width)x\\(size.height), \\(fps) fps, \\(kbps/1000) kbps")
}

if let audioTrack = audioTracks.first {
    let kbps = try await audioTrack.load(.estimatedDataRate)
    print("Audio: \\(kbps/1000) kbps")
}
"""
        CodeSheetViewController.showCodeSheet(from: self, code: snippet)
    }

    @objc private func showSwiftUI() {
        let swiftUIView = AssetInspectorSwiftUIView()
        let hostingVC = UIHostingController(rootView: swiftUIView)
        hostingVC.title = "Asset Inspector (SwiftUI)"
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}
