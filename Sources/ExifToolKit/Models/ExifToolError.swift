//
//  ExifToolError.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

public enum ExifToolError: Error, LocalizedError, Equatable {
    case exiftoolNotFound(searchedPaths: [String])
    case fileNotFound(String)
    case processFailure(exitCode: Int32, stderr: String)
    case parseFailure(String)
    case binaryNotExecutable(String)

    public var errorDescription: String? {
        switch self {
        case .exiftoolNotFound(let paths):
            return "exiftool not found. Searched: \(paths.joined(separator: ", "))"
            
        case .fileNotFound(let path):
            return "File not found: \(path)"
            
        case .processFailure(let code, let stderr):
            return "exiftool exited \(code): \(stderr)"
            
        case .parseFailure(let detail):
            return "Failed to parse exiftool output: \(detail)"
        
        case .binaryNotExecutable(let path):
            return "Bundled exiftool binary could not be made executable at: \(path)"
        }
    }
}
