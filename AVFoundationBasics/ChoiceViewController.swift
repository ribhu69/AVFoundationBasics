import UIKit

class ChoiceViewController: UIViewController {

    // TableView to display choices
    var tableView: UITableView!

    // Data source for the TableView
    let choices = ["Camera", "Playback", "Miscellaneous"]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        // Set the title for the ViewController
        self.title = "Choices"

        // Initialize the TableView
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self

        // Register a UITableViewCell for use
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChoiceCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Add the TableView to the ViewController's view
        self.view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
    }
}

extension ChoiceViewController: UITableViewDelegate, UITableViewDataSource {

    // Number of rows in the TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices.count
    }

    // Cell configuration for each row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChoiceCell", for: indexPath)
        cell.textLabel?.text = choices[indexPath.row]
        return cell
    }

    // Handle row selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selectedChoice = choices[indexPath.row]
        print("Selected Choice: \(selectedChoice)")

        // Handle navigation or actions based on the selected choice
        switch selectedChoice {
        case "Camera":
            navigationController?.pushViewController(CameraViewController(), animated: true)
        case "Playback":
            navigationController?.pushViewController(PlaybackListController(), animated: true)
            break
        case "Miscellaneous":
            print("Yet to explore Miscellanous areas")
        default:
            break
        }
    }
}
