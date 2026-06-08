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

        // Multiple files: separated by blank lines, SourceFile line identifies each file
        var results:      [ExifMetadata]   = []
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

            guard let (key, value) = parseLine(trimmed) else { continue }

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
            guard !trimmed.isEmpty else { continue }
            if let (key, value) = parseLine(trimmed) {
                pairs[key] = value
            }
        }
        return pairs
    }

    /// Parses both formats:
    /// - Default: "File Name                       : IMG_0003.HEIC"
    /// - Short (-S): "FileName: IMG_0003.HEIC"
    private func parseLine(_ line: String) -> (key: String, value: String)? {
        guard let colonIdx = line.firstIndex(of: ":") else { return nil }

        let rawKey = String(line[..<colonIdx]).trimmingCharacters(in: .whitespaces)
        let value  = String(line[line.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)

        guard !rawKey.isEmpty else { return nil }

        // Normalize: "File Name" → "File Name" (keep spaces, this IS the human-readable key)
        return (rawKey, value)
    }
}
