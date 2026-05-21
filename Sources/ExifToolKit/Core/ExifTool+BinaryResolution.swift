//
//  ExifTool+BinaryResolution.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

extension ExifTool {

    static let searchPaths = [
        "/opt/homebrew/bin/exiftool",
        "/usr/local/bin/exiftool",
        "/usr/bin/exiftool",
    ]

    func resolveExecutable() throws -> String {
        if let custom = config.executablePath {
            guard FileManager.default.isExecutableFile(atPath: custom) else {
                throw ExifToolError.exiftoolNotFound(searchedPaths: [custom])
            }
            resolvedPath = custom
            return custom
        }

        if let cached = resolvedPath { return cached }

        for path in Self.searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                resolvedPath = path
                return path
            }
        }

        throw ExifToolError.exiftoolNotFound(searchedPaths: Self.searchPaths)
    }
}
