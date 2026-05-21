//
//  NativeExtractor.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation
import UniformTypeIdentifiers

/// Routes extraction to the correct native backend based on file type.
public struct NativeExtractor {
    
    // Known image extensions
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "heic", "heif", "png", "tiff", "tif", "bmp",
        "gif", "webp", "raw", "cr2", "cr3", "nef", "arw", "dng",
        "orf", "rw2", "pef", "srw", "raf", "3fr", "fff", "iiq",
        "erf", "mrw", "nrw", "rwl", "sr2", "x3f", "ico", "cur",
        "psd", "svg", "jp2", "j2k", "jpf", "jpx", "jpm", "avif"
    ]

    private static let audioVideoExtensions: Set<String> = [
        "mov", "mp4", "m4v", "avi", "mkv", "wmv", "flv", "webm",
        "m4a", "mp3", "aac", "wav", "flac", "ogg", "wma", "aiff",
        "aif", "opus", "m4b", "3gp", "3g2", "mts", "m2ts", "ts"
    ]

    public init() {}

    /// Extract metadata from a single file.
    public func extract(from url: URL) async throws -> ExifMetadata {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ExifToolError.fileNotFound(url.path)
        }

        let ext = url.pathExtension.lowercased()
        let uti = UTType(filenameExtension: ext)

        if isImage(uti, ext: ext) {
            return try extractImage(from: url)
        } else if isAudioVideo(uti, ext: ext) {
            return try await extractAudioVideo(from: url)
        } else if isPDF(uti, ext: ext) {
            return try extractPDF(from: url)
        } else {
            return ExifMetadata(fileURL: url, raw: fileAttributes(for: url))
        }
    }

    /// Extract metadata from multiple files concurrently.
    public func extract(from urls: [URL]) async throws -> [ExifMetadata] {
        try await withThrowingTaskGroup(of: ExifMetadata.self) { group in
            for url in urls {
                group.addTask { try await self.extract(from: url) }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }

    // MARK: - Type Detection

    func isImage(_ uti: UTType?, ext: String) -> Bool {
        if let uti, uti.conforms(to: .image) { return true }
        return Self.imageExtensions.contains(ext)
    }

    func isAudioVideo(_ uti: UTType?, ext: String) -> Bool {
        if let uti, (uti.conforms(to: .audiovisualContent)
            || uti.conforms(to: .audio)
            || uti.conforms(to: .movie)
            || uti.conforms(to: .video)) { return true }
        return Self.audioVideoExtensions.contains(ext)
    }

    func isPDF(_ uti: UTType?, ext: String) -> Bool {
        if let uti, uti.conforms(to: .pdf) { return true }
        return ext == "pdf"
    }

    // MARK: - File Attributes fallback

    func fileAttributes(for url: URL) -> [String: String] {
        var pairs: [String: String] = [:]
        pairs["FileName"] = url.lastPathComponent
        pairs["FileType"] = url.pathExtension.uppercased()

        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
            if let size = attrs[.size] as? Int {
                pairs["FileSize"] = "\(size) bytes"
            }
            if let modified = attrs[.modificationDate] as? Date {
                pairs["FileModifyDate"] = ISO8601DateFormatter().string(from: modified)
            }
            if let created = attrs[.creationDate] as? Date {
                pairs["FileCreateDate"] = ISO8601DateFormatter().string(from: created)
            }
        }

        return pairs
    }
}
