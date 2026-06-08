//
//  ExifTool+ProcessRunner.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

extension ExifTool {
    func runBatch(execPath: (perl: String, script: String), urls: [URL]) async throws -> [ExifMetadata] {
        var args = buildPerlArgs(script: execPath.script)
        if config.numericOutput { args.append("-n") }
        args += config.extraArguments
        args += urls.map(\.path)

        let (stdout, stderr, exitCode) = try await runProcess(execPath.perl, arguments: args)

        guard exitCode == 0 || exitCode == 1
        else { throw ExifToolError.processFailure(exitCode: exitCode, stderr: stderr) }

        return try parseOutput(stdout, fileURLs: urls)
    }

    func runProcess(
        _ execPath: String,
        arguments: [String]
    ) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: execPath)
                    process.arguments = arguments

                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()
                    process.standardOutput = stdoutPipe
                    process.standardError = stderrPipe

                    try process.run()
                    process.waitUntilExit()

                    let stdout = String(
                        data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
                        encoding: .utf8
                    ) ?? ""
                    let stderr = String(
                        data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
                        encoding: .utf8
                    ) ?? ""

                    continuation.resume(returning: (stdout, stderr, process.terminationStatus))
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Build Perl arguments
    /// Passes -I flag so Perl finds the bundled lib/perl5 modules
    func buildPerlArgs(script: String) -> [String] {
        var args: [String] = []
        
        // Use lib from the same destination folder as the script
        let perl5Path = libDestination().appendingPathComponent("perl5").path
        if FileManager.default.fileExists(atPath: perl5Path) {
            args += ["-I", perl5Path]
        }
        
        args.append(script)
        return args
    }
}
