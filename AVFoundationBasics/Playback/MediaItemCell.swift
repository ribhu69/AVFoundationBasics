//
//  MediaItemCell.swift
//  AVFoundationBasics
//
//  Created by Arkaprava Ghosh on 08/08/24.
//

import Foundation
import UIKit

class MediaItemCell: UITableViewCell {
    
    // Create UI elements for the cell
    
    private var image : UIImage?
    let thumbnail : UIImageView = {
        let thumbnail = UIImageView(image: UIImage(named: "placeholderImg"))
        thumbnail.contentMode = .scaleAspectFit
        thumbnail.translatesAutoresizingMaskIntoConstraints = false
        return thumbnail
        
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Add the labels to the cell's content view
        contentView.addSubview(thumbnail)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        // Set up constraints for the labels
        NSLayoutConstraint.activate([
            
            thumbnail.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            thumbnail.topAnchor.constraint(equalTo: contentView.topAnchor , constant: 16),
            thumbnail.bottomAnchor.constraint(equalTo: contentView.bottomAnchor , constant: -16),
            thumbnail.widthAnchor.constraint(equalToConstant: 50),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    private func getThumbnail(for video: Video) {
        
        if image == nil {
            let sources = video.sources
            if !sources.isEmpty {
                var srcString = sources[0]
                srcString = srcString.replacingAfterSample(with: video.thumb) ?? "Emptystring"
                if !srcString.starts(with: "Emptystring") {
                    print("SrcString: \(srcString)")
                    URLSession.shared.dataTask(with: URLRequest(url: URL(string: srcString)!)) { [weak self] data, resp, error in
                        guard let self,
                              let data else {return}
                        DispatchQueue.main.async {
                            self.image = UIImage(data: data)
                            self.thumbnail.image = self.image!
                        }
                    }.resume()
                }
            }
        }
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configure the cell with data
    func configure(with video: Video) {
        titleLabel.text = video.title
        descriptionLabel.text = video.description
        getThumbnail(for: video)
       
        
    }
}
