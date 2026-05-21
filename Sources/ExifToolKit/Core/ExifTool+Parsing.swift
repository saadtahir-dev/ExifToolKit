//
//  ExifTool+Parsing.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

extension ExifTool {
    func parseOutput(_ output: String, fileURLs: [URL]) throws -> [ExifMetadata] {
        if fileURLs.count == 1 {
            return [ExifMetadata(fileURL: fileURLs[0], raw: parsePairs(from: output))]
        }

        var results:      [ExifMetadata]  = []
        var currentPairs: [String: String] = [:]
        var currentURL:   URL?

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                if let url = currentURL, !currentPairs.isEmpty {
                    results.append(ExifMetadata(fileURL: url, raw: currentPairs))
                    currentPairs = [:]
                    currentURL   = nil
                }
                continue
            }

            guard let colonIdx = trimmed.firstIndex(of: ":") else { continue }

            let key   = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)

            if key == "SourceFile" {
                currentURL = URL(fileURLWithPath: value)
            } else {
                currentPairs[key] = value
            }
        }

        if let url = currentURL, !currentPairs.isEmpty {
            results.append(ExifMetadata(fileURL: url, raw: currentPairs))
        }

        return results
    }

    func parsePairs(from output: String) -> [String: String] {
        var pairs: [String: String] = [:]

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty,
                  let colonIdx = trimmed.firstIndex(of: ":")
            else { continue }

            let key   = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)

            pairs[key] = value
        }

        return pairs
    }
}
