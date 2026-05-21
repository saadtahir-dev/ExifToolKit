//
//  File.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

public struct ExifMetadata: Sendable {
    public let fileURL: URL
    public let raw: [String: String]
    
    public subscript(_ tag: ExifTag) -> String? {
        raw[tag.rawValue]
    }
    
    // MARK: - Camera
    public var make: String?        { self[.make] }
    public var model: String?       { self[.model] }
    public var lensModel: String?   { self[.lensModel] }
    
    // MARK: - Exposure
    public var exposureTime: String?  { self[.exposureTime] }
    public var fNumber: Double?       { self[.fNumber].flatMap(Double.init) }
    public var iso: Int?              { self[.iso].flatMap(Int.init) }
    public var focalLength: String?   { self[.focalLength] }
    
    // MARK: - Date
    public var dateTimeOriginal: Date? { self[.dateTimeOriginal].flatMap(ExifMetadata.parseExifDate) }
    public var createDate: Date?       { self[.createDate].flatMap(ExifMetadata.parseExifDate) }
    
    // MARK: - GPS
    public var gpsCoordinate: (latitude: Double, longitude: Double)? {
        guard let lat = self[.gpsLatitude].flatMap(parseGPS),
              let lon = self[.gpsLongitude].flatMap(parseGPS)
        else { return nil }
        return (lat, lon)
    }
    
    // MARK: - Image
    public var imageSize: (width: Int, height: Int)? {
        guard let w = self[.imageWidth].flatMap(Int.init),
              let h = self[.imageHeight].flatMap(Int.init)
        else { return nil }
        return (w, h)
    }
}

// MARK: - Helpers
extension ExifMetadata {
    private static let exifDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy:MM:dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func parseExifDate(_ s: String) -> Date? {
        exifDateFormatter.date(from: s)
    }

    private func parseGPS(_ s: String) -> Double? {
        if let d = Double(s) { return d }
        let pattern = #"(\d+)\s+deg\s+(\d+)'\s+([\d.]+)"\s+([NSEW])"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let dRange = Range(match.range(at: 1), in: s),
              let mRange = Range(match.range(at: 2), in: s),
              let sRange = Range(match.range(at: 3), in: s),
              let dirRange = Range(match.range(at: 4), in: s)
        else { return nil }

        let degrees = Double(s[dRange])!
        let minutes = Double(s[mRange])!
        let seconds = Double(s[sRange])!
        let dir = String(s[dirRange])

        var decimal = degrees + minutes / 60 + seconds / 3600
        if dir == "S" || dir == "W" { decimal = -decimal }
        return decimal
    }
}
