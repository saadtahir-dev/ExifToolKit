//
//  ExifTool+Backend.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

extension ExifTool {
    public func nativeMetadataStream(
        for fileURLs: [URL],
        chunkSize: Int? = nil,
        maxConcurrency: Int? = nil
    ) -> AsyncStream<MetadataResult> {
        let chunkSz     = chunkSize ?? config.chunkSize
        let concurrency = maxConcurrency ?? config.maxConcurrency
        let chunks      = fileURLs.chunked(into: chunkSz)
        let extractor   = NativeExtractor()

        return AsyncStream { continuation in
            Task {
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

                        group.addTask {
                            for url in capturedChunk {
                                do {
                                    let meta = try await extractor.extract(from: url)
                                    continuation.yield(.success(meta))
                                } catch {
                                    continuation.yield(.failure(url: url, error: error))
                                }
                            }
                        }
                    }

                    await group.waitForAll()
                }

                continuation.finish()
            }
        }
    }
}
