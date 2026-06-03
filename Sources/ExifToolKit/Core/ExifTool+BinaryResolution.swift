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
    
    /// System Perl paths
    static let perlPaths = [
        "/usr/bin/perl",
        "/usr/bin/perl5.34",
        "/usr/local/bin/perl",
        "/opt/homebrew/bin/perl",
    ]
    
    /// System exiftool script paths (fallback if not bundled)
    static let systemExiftoolPaths = [
        "/opt/homebrew/bin/exiftool",
        "/usr/local/bin/exiftool",
        "/usr/bin/exiftool",
    ]
    
    // MARK: - Destination (uses custom appSupportURL or default)
    func scriptDestination() -> URL {
        let base = config.applicationSupportURL
        ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExifToolKit", isDirectory: true)
        
        return base.appendingPathComponent("exiftool")
    }
    
    func libDestination() -> URL {
        let base = config.applicationSupportURL
        ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExifToolKit", isDirectory: true)
        
        return base.appendingPathComponent("lib")
    }
    
    // MARK: - Resolve
    func resolveExecutable() throws -> (perl: String, script: String) {
        // 1. Custom executable path
        if let custom = config.executablePath {
            guard FileManager.default.isExecutableFile(atPath: custom) else {
                throw ExifToolError.exiftoolNotFound(searchedPaths: [custom])
            }
            return (try resolvePerl(), custom)
        }
        
        // 2. Cached path from previous resolution
        if let cached = resolvedPath {
            return (try resolvePerl(), cached)
        }
        
        // 3. Bundled SPM resources — copy to applicationSupportURL then use cached
        if let bundledScript = Bundle.module.url(forResource: "exiftool", withExtension: nil) {
            let scriptPath = try installBundledScript(from: bundledScript)
            resolvedPath   = scriptPath
            return (try resolvePerl(), scriptPath)
        }
        
        // 4. System exiftool
        for path in Self.systemExiftoolPaths {
            if FileManager.default.fileExists(atPath: path) {
                resolvedPath = path
                return (try resolvePerl(), path)
            }
        }
        
        throw ExifToolError.exiftoolNotFound(searchedPaths: Self.systemExiftoolPaths)
    }
    
    private func resolvePerl() throws -> String {
        for path in Self.perlPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        throw ExifToolError.exiftoolNotFound(searchedPaths: Self.perlPaths)
    }
    
    // MARK: - Install bundled script to writable location
    private func installScript(from resourcesPath: String) throws -> String {
        let fm         = FileManager.default
        let dest       = scriptDestination()
        let libDest    = libDestination()
        
        // Already installed
        if fm.fileExists(atPath: dest.path) {
            return dest.path
        }
        
        // Create destination directory
        try fm.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Copy exiftool script
        let srcScript = (resourcesPath as NSString).appendingPathComponent("exiftool")
        if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
        try fm.copyItem(atPath: srcScript, toPath: dest.path)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
        
        // Copy lib folder
        let srcLib = (resourcesPath as NSString).appendingPathComponent("lib")
        if fm.fileExists(atPath: srcLib) {
            if fm.fileExists(atPath: libDest.path) { try fm.removeItem(at: libDest) }
            try fm.copyItem(atPath: srcLib, toPath: libDest.path)
        }
        
        return dest.path
    }
    
    private func installBundledScript(from source: URL) throws -> String {
        let fm   = FileManager.default
        let dest = scriptDestination()
        
        // Already installed
        if fm.fileExists(atPath: dest.path) {
            return dest.path
        }
        
        try fm.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
        try fm.copyItem(at: source, to: dest)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
        
        // Copy bundled lib
        if let libURL = Bundle.module.url(forResource: "lib", withExtension: nil) {
            let libDest = libDestination()
            if fm.fileExists(atPath: libDest.path) { try fm.removeItem(at: libDest) }
            try fm.copyItem(at: libURL, to: libDest)
        }
        
        return dest.path
    }
}
