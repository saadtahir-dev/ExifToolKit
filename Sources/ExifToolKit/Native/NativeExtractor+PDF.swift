//
//  NativeExtractor+PDF.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation
import CoreGraphics

extension NativeExtractor {
    func extractPDF(from url: URL) throws -> ExifMetadata {
        guard let doc = CGPDFDocument(url as CFURL) else {
            throw ExifToolError.parseFailure("Failed to open PDF: \(url.lastPathComponent)")
        }

        var pairs: [String: String] = [:]

        // File info
        pairs["File Name"] = url.lastPathComponent
        pairs["File Type"] = "PDF"
        pairs["MIME Type"] = "application/pdf"
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            pairs["File Size"] = "\(size) bytes"
        }

        // PDF version
        var major: Int32 = 0
        var minor: Int32 = 0
        doc.getVersion(majorVersion: &major, minorVersion: &minor)
        pairs["PDF Version"] = "\(major).\(minor)"

        // Page count + dimensions
        pairs["Page Count"] = "\(doc.numberOfPages)"
        if let page = doc.page(at: 1) {
            let bounds = page.getBoxRect(.mediaBox)
            pairs["Page Width"]  = String(format: "%.0f", bounds.width)
            pairs["Page Height"] = String(format: "%.0f", bounds.height)
        }

        // Encryption
        pairs["Encrypted"] = doc.isEncrypted ? "Yes" : "No"

        guard let info = doc.info else {
            return ExifMetadata(fileURL: url, raw: pairs)
        }

        func getString(_ key: String) -> String? {
            var ref: CGPDFStringRef?
            guard CGPDFDictionaryGetString(info, key, &ref), let ref else { return nil }
            return CGPDFStringCopyTextString(ref) as String?
        }

        func getDate(_ key: String) -> String? {
            var ref: CGPDFStringRef?
            guard CGPDFDictionaryGetString(info, key, &ref), let ref else { return nil }
            guard let date = CGPDFStringCopyDate(ref) else { return nil }
            return ISO8601DateFormatter().string(from: date as CFDate as Date)
        }

        if let title    = getString("Title"),    !title.isEmpty    { pairs["Title"]       = title }
        if let author   = getString("Author"),   !author.isEmpty   { pairs["Author"]      = author }
        if let subject  = getString("Subject"),  !subject.isEmpty  { pairs["Subject"]     = subject }
        if let keywords = getString("Keywords"), !keywords.isEmpty { pairs["Keywords"]    = keywords }
        if let creator  = getString("Creator"),  !creator.isEmpty  { pairs["Creator"]     = creator }
        if let producer = getString("Producer"), !producer.isEmpty { pairs["Producer"]    = producer }
        if let created  = getDate("CreationDate")                  { pairs["Create Date"] = created }
        if let modified = getDate("ModDate")                       { pairs["Modify Date"] = modified }

        return ExifMetadata(fileURL: url, raw: pairs)
    }
}
