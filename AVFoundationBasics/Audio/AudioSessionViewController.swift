import UIKit
import AVFoundation
import SwiftUI

// MARK: - AudioSessionViewController

class AudioSessionViewController: UIViewController {

    // MARK: - Data
    private struct SessionInfo {
        var category: String = ""
        var mode: String = ""
        var sampleRate: String = ""
        var ioBufferDuration: String = ""
        var outputChannels: String = ""
        var inputChannels: String = ""
        var outputLatency: String = ""
        var inputAvailable: String = ""
        var inputPortName: String = ""
        var inputPortType: String = ""
        var outputPortName: String = ""
        var outputPortType: String = ""
    }

    private var sessionInfo = SessionInfo()
    private var isSessionActive = false
    private var selectedCategoryIndex = 0

    private let categories: [(label: String, value: AVAudioSession.Category)] = [
        ("ambient", .ambient),
        ("soloAmbient", .soloAmbient),
        ("playback", .playback),
        ("record", .record),
        ("play+rec", .playAndRecord)
    ]

    // MARK: - UI
    private var tableView: UITableView!
    private let categorySegment: UISegmentedControl
    private let activateButton = UIButton(type: .system)

    // MARK: - Init

    init() {
        let items = categories.map { $0.label }
        categorySegment = UISegmentedControl(items: items)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio Session"
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupTableView()
        refreshSessionInfo()
    }

    // MARK: - Nav Bar

    private func setupNavBar() {
        let refreshButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
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
        navigationItem.rightBarButtonItems = [swiftUIButton, codeButton, refreshButton]
    }

    // MARK: - TableView Setup

    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SegmentCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ButtonCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        categorySegment.selectedSegmentIndex = 1 // soloAmbient default
        categorySegment.addTarget(self, action: #selector(categorySegmentChanged), for: .valueChanged)
    }

    // MARK: - Session Info

    private func refreshSessionInfo() {
        let session = AVAudioSession.sharedInstance()
        sessionInfo.category = session.category.rawValue.components(separatedBy: ".").last ?? session.category.rawValue
        sessionInfo.mode = session.mode.rawValue.components(separatedBy: ".").last ?? session.mode.rawValue
        sessionInfo.sampleRate = String(format: "%.0f Hz", session.sampleRate)
        sessionInfo.ioBufferDuration = String(format: "%.2f ms", session.ioBufferDuration * 1000)
        sessionInfo.outputChannels = "\(session.outputNumberOfChannels)"
        sessionInfo.inputChannels = "\(session.inputNumberOfChannels)"
        sessionInfo.outputLatency = String(format: "%.2f ms", session.outputLatency * 1000)
        sessionInfo.inputAvailable = session.isInputAvailable ? "Yes" : "No"

        // Route info
        let route = session.currentRoute
        if let input = route.inputs.first {
            sessionInfo.inputPortName = input.portName
            sessionInfo.inputPortType = input.portType.rawValue.components(separatedBy: ".").last ?? input.portType.rawValue
        } else {
            sessionInfo.inputPortName = "None"
            sessionInfo.inputPortType = "—"
        }
        if let output = route.outputs.first {
            sessionInfo.outputPortName = output.portName
            sessionInfo.outputPortType = output.portType.rawValue.components(separatedBy: ".").last ?? output.portType.rawValue
        } else {
            sessionInfo.outputPortName = "None"
            sessionInfo.outputPortType = "—"
        }

        tableView.reloadData()
        updateActivateButton()
    }

    private func updateActivateButton() {
        activateButton.setTitle(isSessionActive ? "Deactivate Session" : "Activate Session", for: .normal)
        activateButton.setTitleColor(isSessionActive ? .systemRed : .systemBlue, for: .normal)
    }

    // MARK: - Actions

    @objc private func refreshTapped() {
        refreshSessionInfo()
    }

    @objc private func categorySegmentChanged() {
        selectedCategoryIndex = categorySegment.selectedSegmentIndex
    }

    @objc private func activateDeactivateTapped() {
        let session = AVAudioSession.sharedInstance()
        do {
            if isSessionActive {
                try session.setActive(false)
                isSessionActive = false
            } else {
                let cat = categories[categorySegment.selectedSegmentIndex].value
                try session.setCategory(cat, mode: .default)
                try session.setActive(true)
                isSessionActive = true
            }
            refreshSessionInfo()
        } catch {
            let alert = UIAlertController(title: "Session Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func showCode() {
        let snippet = """
import AVFoundation

// Get shared audio session
let session = AVAudioSession.sharedInstance()

// Set category and mode
try session.setCategory(.playback, mode: .default)

// Activate the session
try session.setActive(true)

// Read session properties
let sampleRate = session.sampleRate         // e.g. 44100.0
let bufferDuration = session.ioBufferDuration
let outputChannels = session.outputNumberOfChannels
let inputChannels = session.inputNumberOfChannels
let outputLatency = session.outputLatency
let inputAvailable = session.isInputAvailable

// Inspect current audio route
let route = session.currentRoute
for input in route.inputs {
    print("Input: \\(input.portName) type: \\(input.portType.rawValue)")
}
for output in route.outputs {
    print("Output: \\(output.portName) type: \\(output.portType.rawValue)")
}

// Deactivate session
try session.setActive(false)
"""
        CodeSheetViewController.showCodeSheet(from: self, code: snippet)
    }

    @objc private func showSwiftUI() {
        let swiftUIView = AudioSessionSwiftUIView()
        let hostingVC = UIHostingController(rootView: swiftUIView)
        hostingVC.title = "Audio Session (SwiftUI)"
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension AudioSessionViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 8   // Session info rows
        case 1: return 2   // Segment control + Activate button
        case 2: return 2   // Route info (input + output)
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Current Session"
        case 1: return "Change Category"
        case 2: return "Route Info"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            switch indexPath.row {
            case 0: config.text = "Category"; config.secondaryText = sessionInfo.category
            case 1: config.text = "Mode"; config.secondaryText = sessionInfo.mode
            case 2: config.text = "Sample Rate"; config.secondaryText = sessionInfo.sampleRate
            case 3: config.text = "IO Buffer Duration"; config.secondaryText = sessionInfo.ioBufferDuration
            case 4: config.text = "Output Channels"; config.secondaryText = sessionInfo.outputChannels
            case 5: config.text = "Input Channels"; config.secondaryText = sessionInfo.inputChannels
            case 6: config.text = "Output Latency"; config.secondaryText = sessionInfo.outputLatency
            case 7: config.text = "Input Available"; config.secondaryText = sessionInfo.inputAvailable
            default: break
            }
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell

        case 1:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentCell", for: indexPath)
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                categorySegment.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(categorySegment)
                NSLayoutConstraint.activate([
                    categorySegment.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                    categorySegment.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                    categorySegment.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                    categorySegment.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
                ])
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                activateButton.translatesAutoresizingMaskIntoConstraints = false
                activateButton.addTarget(self, action: #selector(activateDeactivateTapped), for: .touchUpInside)
                cell.contentView.addSubview(activateButton)
                NSLayoutConstraint.activate([
                    activateButton.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                    activateButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                    activateButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
                ])
                updateActivateButton()
                cell.selectionStyle = .none
                return cell
            }

        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                config.text = "Input: \(sessionInfo.inputPortName)"
                config.secondaryText = "Type: \(sessionInfo.inputPortType)"
            } else {
                config.text = "Output: \(sessionInfo.outputPortName)"
                config.secondaryText = "Type: \(sessionInfo.outputPortType)"
            }
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 { return 56 }
        return UITableView.automaticDimension
    }
}
