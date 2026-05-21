//
//  File.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation

public struct ExifTag: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    // MARK: - Camera
    public static let make: ExifTag             = "Make"
    public static let model: ExifTag            = "Model"
    public static let software: ExifTag         = "Software"
    public static let lensMake: ExifTag         = "LensMake"
    public static let lensModel: ExifTag        = "LensModel"

    // MARK: - Exposure
    public static let exposureTime: ExifTag     = "ExposureTime"
    public static let fNumber: ExifTag          = "FNumber"
    public static let iso: ExifTag              = "ISO"
    public static let exposureProgram: ExifTag  = "ExposureProgram"
    public static let meteringMode: ExifTag     = "MeteringMode"
    public static let flash: ExifTag            = "Flash"
    public static let focalLength: ExifTag      = "FocalLength"

    // MARK: - Date/Time
    public static let dateTimeOriginal: ExifTag = "DateTimeOriginal"
    public static let createDate: ExifTag       = "CreateDate"
    public static let modifyDate: ExifTag       = "ModifyDate"

    // MARK: - GPS
    public static let gpsLatitude: ExifTag      = "GPSLatitude"
    public static let gpsLongitude: ExifTag     = "GPSLongitude"
    public static let gpsAltitude: ExifTag      = "GPSAltitude"

    // MARK: - Image
    public static let imageWidth: ExifTag       = "ImageWidth"
    public static let imageHeight: ExifTag      = "ImageHeight"
    public static let colorSpace: ExifTag       = "ColorSpace"
    public static let orientation: ExifTag      = "Orientation"
    public static let xResolution: ExifTag      = "XResolution"
    public static let yResolution: ExifTag      = "YResolution"

    // MARK: - File
    public static let fileName: ExifTag         = "FileName"
    public static let fileSize: ExifTag         = "FileSize"
    public static let mimeType: ExifTag         = "MIMEType"
    public static let fileType: ExifTag         = "FileType"
}
