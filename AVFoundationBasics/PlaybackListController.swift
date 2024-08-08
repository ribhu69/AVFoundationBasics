//
//  PlaybackListController.swift
//  AVFoundationBasics
//
//  Created by Arkaprava Ghosh on 08/08/24.
//

import UIKit

import UIKit

class PlaybackListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    

    private var mediaItems = [Video]()
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Initialize and set up the table view
        tableView = UITableView(frame: view.bounds)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MediaItemCell.self, forCellReuseIdentifier: "MediaItemCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        loadJSONData()
    }
    
    func loadJSONData() {
        if let fileURL = Bundle.main.url(forResource: "PublicData", withExtension: "json") {
            do {
                let data = try Data(contentsOf: fileURL)
                
                // Decode the JSON data into the PublicData structure
                let publicData = try JSONDecoder().decode(PublicData.self, from: data)
                
                // Assuming you only want the videos from the first category
                if let firstCategory = publicData.categories.first {
                    self.mediaItems = firstCategory.videos
                }
                
                // Reload the table view with the new data
                tableView.reloadData()
            } catch {
                print("Error loading or decoding JSON: \(error.localizedDescription)")
            }
        } else {
            print("PublicData.json file not found")
        }
    }
    
    // UITableViewDataSource Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MediaItemCell", for: indexPath) as? MediaItemCell else {
            return UITableViewCell()
        }
        
        // Configure the cell with the media item
        let video = mediaItems[indexPath.row]
        cell.configure(with: video)
        
        return cell
    }
    
    // UITableViewDelegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Handle
    }
}
