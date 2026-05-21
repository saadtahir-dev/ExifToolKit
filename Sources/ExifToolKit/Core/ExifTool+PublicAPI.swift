//
//  ExifTool+PublicAPI.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

// MARK: - Single file
extension ExifTool {
    /// Extract metadata from a single file using the configured backend.
    public func metadata(for fileURL: URL) async throws -> ExifMetadata {
        switch config.backend {
        case .native:
            return try await NativeExtractor().extract(from: fileURL)
            
        case .exiftoolBinary:
            return try await runBinaryMetadata(for: [fileURL]).first
            ?? { throw ExifToolError.fileNotFound(fileURL.path) }()
            
        case .auto:
            if isExiftoolInstalled() {
                return try await runBinaryMetadata(for: [fileURL]).first
                ?? { throw ExifToolError.fileNotFound(fileURL.path) }()
            } else {
                return try await NativeExtractor().extract(from: fileURL)
            }
        }
    }
}

// MARK: - Batch
extension ExifTool {
    public func metadata(for fileURLs: [URL]) async throws -> [ExifMetadata] {
        guard !fileURLs.isEmpty else { return [] }
        
        switch config.backend {
        case .native:
            return try await NativeExtractor().extract(from: fileURLs)
            
        case .exiftoolBinary:
            return try await runBinaryMetadata(for: fileURLs)
            
        case .auto:
            if isExiftoolInstalled() {
                return try await runBinaryMetadata(for: fileURLs)
            } else {
                return try await NativeExtractor().extract(from: fileURLs)
            }
        }
    }
}

// MARK: - Specific tags (binary only)
extension ExifTool {
    public func metadata(for fileURL: URL, tags: [ExifTag]) async throws -> ExifMetadata {
        let execPath = try resolveExecutable()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ExifToolError.fileNotFound(fileURL.path)
        }
        
        var args = ["-S"]
        if config.numericOutput { args.append("-n") }
        args += tags.map { "-\($0.rawValue)" }
        args += config.extraArguments
        args.append(fileURL.path)
        
        let (stdout, _, exitCode) = try await runProcess(execPath, arguments: args)
        guard exitCode == 0 || exitCode == 1
        else { throw ExifToolError.processFailure(exitCode: exitCode, stderr: "") }
        
        return ExifMetadata(fileURL: fileURL, raw: parsePairs(from: stdout))
    }
}

// MARK: - Stream
extension ExifTool {
    public func metadataStream(
        for fileURLs: [URL],
        chunkSize: Int? = nil,
        maxConcurrency: Int? = nil
    ) -> AsyncStream<MetadataResult> {
        switch config.backend {
        case .native:
            return nativeMetadataStream(for: fileURLs, chunkSize: chunkSize, maxConcurrency: maxConcurrency)
            
        case .exiftoolBinary:
            return binaryMetadataStream(for: fileURLs, chunkSize: chunkSize, maxConcurrency: maxConcurrency)
            
        case .auto:
            if isExiftoolInstalled() {
                return binaryMetadataStream(for: fileURLs, chunkSize: chunkSize, maxConcurrency: maxConcurrency)
            } else {
                return nativeMetadataStream(for: fileURLs, chunkSize: chunkSize, maxConcurrency: maxConcurrency)
            }
        }
    }
}

// MARK: - Availability
extension ExifTool {
    public func isAvailable() -> Bool {
        true // native is always available
    }
    
    public func isExiftoolInstalled() -> Bool {
        (try? resolveExecutable()) != nil
    }
}

// MARK: - Internal binary helpers
extension ExifTool {
    func runBinaryMetadata(for fileURLs: [URL]) async throws -> [ExifMetadata] {
        let execPath = try resolveExecutable()
        for url in fileURLs {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ExifToolError.fileNotFound(url.path)
            }
        }
        return try await runBatch(execPath: execPath, urls: fileURLs)
    }
    
    func binaryMetadataStream(
        for fileURLs: [URL],
        chunkSize: Int? = nil,
        maxConcurrency: Int? = nil
    ) -> AsyncStream<MetadataResult> {
        let chunkSz     = chunkSize ?? config.chunkSize
        let concurrency = maxConcurrency ?? config.maxConcurrency
        let chunks      = fileURLs.chunked(into: chunkSz)
        
        return AsyncStream { continuation in
            Task {
                do {
                    let execPath = try self.resolveExecutable()
                    
                    await withTaskGroup(of: Void.self) { group in
                        var active = 0
                        
                        for chunk in chunks {
                            if Task.isCancelled {
                                continuation.finish()
                                return
                            }
                            
                            if active >= concurrency {
                                await group.next()
                                active -= 1
                            }
                            
                            active += 1
                            let capturedChunk = chunk
                            let capturedPath  = execPath
                            
                            group.addTask {
                                // Filter out missing files before invoking exiftool
                                var validURLs: [URL] = []
                                for url in capturedChunk {
                                    if FileManager.default.fileExists(atPath: url.path) {
                                        validURLs.append(url)
                                    } else {
                                        continuation.yield(.failure(
                                            url: url,
                                            error: ExifToolError.fileNotFound(url.path)
                                        ))
                                    }
                                }
                                guard !validURLs.isEmpty else { return }
                                do {
                                    let results = try await self.runBatch(
                                        execPath: capturedPath,
                                        urls: validURLs
                                    )
                                    for meta in results {
                                        continuation.yield(.success(meta))
                                    }
                                } catch {
                                    for url in validURLs {
                                        continuation.yield(.failure(url: url, error: error))
                                    }
                                }
                            }
                        }
                        
                        await group.waitForAll()
                    }
                } catch {
                    continuation.yield(.failure(url: URL(fileURLWithPath: ""), error: error))
                }
                
                continuation.finish()
            }
        }
    }
}
