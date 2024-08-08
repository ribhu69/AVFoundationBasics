//
//  StringExtension.swift
//  AVFoundationBasics
//
//  Created by Arkaprava Ghosh on 08/08/24.
//

import Foundation

extension String {
    /// Replaces the first occurrence of `/sample` in the string with the specified replacement string.
    /// - Parameter replacement: The string to replace `/sample` with.
    /// - Returns: A new string with `/sample` replaced by the provided replacement string.
    func replacingAfterSample(with replacement: String) -> String? {
           // Define the target substring
           let target = "/sample"
           
           // Check if the target exists in the string
           if let range = self.range(of: target) {
               // Create the new string by appending "/" and the replacement string after "/sample"
               let prefix = self[..<range.upperBound]
               let replacedString = prefix + "/" + replacement
               return String(replacedString)
           }
           
           // If the target substring is not found, return nil or the original string
           return nil
       }
}
