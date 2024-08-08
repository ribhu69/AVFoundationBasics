import UIKit

class ChoiceViewController: UIViewController {

    // TableView to display choices
    var tableView: UITableView!

    // Data source for the TableView
    let choices = ["Camera", "Playback", "Miscellaneous"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the title for the ViewController
        self.title = "Choices"

        // Initialize the TableView
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self

        // Register a UITableViewCell for use
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChoiceCell")

        // Add the TableView to the ViewController's view
        self.view.addSubview(tableView)
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
             print("Yet to explore Camera Libraries")
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
