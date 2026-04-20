import UIKit

// MARK: - ChoiceViewController

class ChoiceViewController: UIViewController {

    // MARK: - Data

    private let choices = [
        "Camera",
        "Playback",
        "Audio Player",
        "Audio Recorder",
        "Audio Session",
        "Text to Speech",
        "Asset Inspector"
    ]

    private let descriptions: [String: String] = [
        "Camera":         "AVCaptureSession — photo capture with live preview",
        "Playback":       "AVPlayer + AVPlayerLayer — video playback from URL",
        "Audio Player":   "AVAudioPlayer — tone generation, volume, rate, looping",
        "Audio Recorder": "AVAudioRecorder — record to file, level meter, playback",
        "Audio Session":  "AVAudioSession — categories, modes, route inspection",
        "Text to Speech": "AVSpeechSynthesizer — rate, pitch, volume, language",
        "Asset Inspector": "AVAsset — async metadata loading with modern API"
    ]

    // MARK: - UI

    private var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "AVFoundation Basics"

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChoiceCell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource & Delegate

extension ChoiceViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChoiceCell", for: indexPath)
        let choice = choices[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = choice
        config.secondaryText = descriptions[choice]
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.font = UIFont.systemFont(ofSize: 13)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selectedChoice = choices[indexPath.row]

        switch selectedChoice {
        case "Camera":
            navigationController?.pushViewController(CameraViewController(), animated: true)
        case "Playback":
            navigationController?.pushViewController(PlaybackListController(), animated: true)
        case "Audio Player":
            navigationController?.pushViewController(AudioPlayerViewController(), animated: true)
        case "Audio Recorder":
            navigationController?.pushViewController(AudioRecorderViewController(), animated: true)
        case "Audio Session":
            navigationController?.pushViewController(AudioSessionViewController(), animated: true)
        case "Text to Speech":
            navigationController?.pushViewController(TextToSpeechViewController(), animated: true)
        case "Asset Inspector":
            navigationController?.pushViewController(AssetInspectorViewController(), animated: true)
        default:
            break
        }
    }
}
