//
//  ModelFile.swift
//  AVFoundationBasics
//
//  Created by Arkaprava Ghosh on 08/08/24.
//

import Foundation

struct Video: Codable {
    let description: String
    let sources: [String]
    let subtitle: String
    let thumb: String
    let title: String
}

// Define the Category struct
struct Category: Codable {
    let name: String
    let videos: [Video]
}

// Define the top-level structure to match your JSON
struct PublicData: Codable {
    let categories: [Category]
}
