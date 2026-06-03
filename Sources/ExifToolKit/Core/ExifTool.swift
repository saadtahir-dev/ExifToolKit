//
//  ExifTool.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

public actor ExifTool {
    
    // MARK: - Configuration
    public struct Configuration: Sendable {
        public var executablePath: String?
        public var extraArguments: [String]
        public var numericOutput: Bool
        public var chunkSize: Int
        public var maxConcurrency: Int
        public var backend: Backend
        
        /// Custom Application Support URL to install exiftool into.
        /// SPM will copy the bundled exiftool script and lib into this folder.
        /// Defaults to ~/Library/Application Support/ExifToolKit/
        /// Example: pass your app's own Application Support folder
        public var applicationSupportURL: URL?
        
        public init(
            executablePath: String? = nil,
            extraArguments: [String] = [],
            numericOutput: Bool = false,
            chunkSize: Int = 1000,
            maxConcurrency: Int = 4,
            backend: Backend = .auto,
            resourcesPath: String? = nil,
            applicationSupportURL: URL? = nil
        ) {
            self.executablePath       = executablePath
            self.extraArguments       = extraArguments
            self.numericOutput        = numericOutput
            self.chunkSize            = chunkSize
            self.maxConcurrency       = maxConcurrency
            self.backend              = backend
            self.applicationSupportURL = applicationSupportURL
        }
    }
    
    public enum MetadataResult: Sendable {
        case success(ExifMetadata)
        case failure(url: URL, error: Error)
    }
    
    public enum Backend: Sendable {
        /// Native Apple APIs (ImageIO + AVFoundation + CoreGraphics).
        /// Fully notarizable, App Store compatible, no binary dependency.
        case native
        
        /// System-installed exiftool binary (brew install exiftool).
        /// Maximum tag coverage. Throws if exiftool is not installed.
        case exiftoolBinary
        
        /// Use system exiftool if installed, otherwise fall back to native.
        case auto
    }
    
    // MARK: - Properties
    internal let config: Configuration
    internal var resolvedPath: String?
    
    // MARK: - Init
    public init(configuration: Configuration = Configuration()) {
        self.config = configuration
    }
}
