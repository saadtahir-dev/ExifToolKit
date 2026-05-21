//
//  NativeExtractor+ImageIO.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation
import ImageIO

extension NativeExtractor {
    func extractImage(from url: URL) throws -> ExifMetadata {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ExifToolError.parseFailure("CGImageSourceCreateWithURL failed for \(url.lastPathComponent)")
        }
        
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw ExifToolError.parseFailure("No properties found in \(url.lastPathComponent)")
        }
        
        var pairs: [String: String] = [:]
        
        // File info
        pairs["FileName"]  = url.lastPathComponent
        pairs["FileType"]  = url.pathExtension.uppercased()
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            pairs["FileSize"] = "\(size) bytes"
        }
        
        // Top-level image props
        if let width = props[kCGImagePropertyPixelWidth as String] as? Int {
            pairs["ImageWidth"] = "\(width)"
        }
        if let height = props[kCGImagePropertyPixelHeight as String] as? Int {
            pairs["ImageHeight"] = "\(height)"
        }
        if let depth = props[kCGImagePropertyDepth as String] as? Int {
            pairs["BitDepth"] = "\(depth)"
        }
        if let orientation = props[kCGImagePropertyOrientation as String] as? Int {
            pairs["Orientation"] = "\(orientation)"
        }
        if let dpi = props[kCGImagePropertyDPIWidth as String] as? Double {
            pairs["XResolution"] = "\(dpi)"
        }
        if let dpi = props[kCGImagePropertyDPIHeight as String] as? Double {
            pairs["YResolution"] = "\(dpi)"
        }
        if let colorModel = props[kCGImagePropertyColorModel as String] as? String {
            pairs["ColorSpace"] = colorModel
        }
        if let profile = props[kCGImagePropertyProfileName as String] as? String {
            pairs["ProfileDescription"] = profile
        }
        
        // EXIF
        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            pairs["ExifVersion"]        = exif[kCGImagePropertyExifVersion as String] as? String
            pairs["DateTimeOriginal"]   = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String
            pairs["CreateDate"]         = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String
            pairs["ExposureTime"]       = (exif[kCGImagePropertyExifExposureTime as String] as? Double).map { formatExposure($0) }
            pairs["FNumber"]            = (exif[kCGImagePropertyExifFNumber as String] as? Double).map { String(format: "%.1f", $0) }
            pairs["ISO"]                = (exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first.map { "\($0)" }
            pairs["ShutterSpeedValue"]  = (exif[kCGImagePropertyExifShutterSpeedValue as String] as? Double).map { String(format: "%.4f", $0) }
            pairs["ApertureValue"]      = (exif[kCGImagePropertyExifApertureValue as String] as? Double).map { String(format: "%.1f", $0) }
            pairs["BrightnessValue"]    = (exif[kCGImagePropertyExifBrightnessValue as String] as? Double).map { String(format: "%.6f", $0) }
            pairs["ExposureCompensation"] = (exif[kCGImagePropertyExifExposureBiasValue as String] as? Double).map { "\($0)" }
            pairs["MeteringMode"]       = (exif[kCGImagePropertyExifMeteringMode as String] as? Int).map { "\($0)" }
            pairs["Flash"]              = (exif[kCGImagePropertyExifFlash as String] as? Int).map { "\($0)" }
            pairs["FocalLength"]        = (exif[kCGImagePropertyExifFocalLength as String] as? Double).map { String(format: "%.1f mm", $0) }
            pairs["FocalLengthIn35mmFormat"] = (exif[kCGImagePropertyExifFocalLenIn35mmFilm as String] as? Int).map { "\($0) mm" }
            pairs["ExposureProgram"]    = (exif[kCGImagePropertyExifExposureProgram as String] as? Int).map { "\($0)" }
            pairs["WhiteBalance"]       = (exif[kCGImagePropertyExifWhiteBalance as String] as? Int).map { "\($0)" }
            pairs["ExifImageWidth"]     = (exif[kCGImagePropertyExifPixelXDimension as String] as? Int).map { "\($0)" }
            pairs["ExifImageHeight"]    = (exif[kCGImagePropertyExifPixelYDimension as String] as? Int).map { "\($0)" }
            pairs["SceneType"]          = (exif[kCGImagePropertyExifSceneType as String] as? Int).map { "\($0)" }
            pairs["ExposureMode"]       = (exif[kCGImagePropertyExifExposureMode as String] as? Int).map { "\($0)" }
            pairs["SensingMethod"]      = (exif[kCGImagePropertyExifSensingMethod as String] as? Int).map { "\($0)" }
            pairs["SubjectArea"]        = (exif[kCGImagePropertyExifSubjectArea as String] as? [Int]).map { $0.map { "\($0)" }.joined(separator: " ") }
            pairs["OffsetTime"]         = exif[kCGImagePropertyExifOffsetTime as String] as? String
            pairs["OffsetTimeOriginal"] = exif[kCGImagePropertyExifOffsetTimeOriginal as String] as? String
            pairs["LensInfo"]           = (exif[kCGImagePropertyExifLensSpecification as String] as? [Double]).map { $0.map { String(format: "%.2f", $0) }.joined(separator: "-") }
            pairs["LensMake"]           = exif[kCGImagePropertyExifLensMake as String] as? String
            pairs["LensModel"]          = exif[kCGImagePropertyExifLensModel as String] as? String
            pairs["SubSecTimeOriginal"] = exif[kCGImagePropertyExifSubsecTimeOriginal as String] as? String
            pairs["SubSecTimeDigitized"] = exif[kCGImagePropertyExifSubsecTimeDigitized as String] as? String
        }
        
        // TIFF (Make, Model, Software etc.)
        if let tiff = props[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            pairs["Make"]         = tiff[kCGImagePropertyTIFFMake as String] as? String
            pairs["Model"]        = tiff[kCGImagePropertyTIFFModel as String] as? String
            pairs["Software"]     = tiff[kCGImagePropertyTIFFSoftware as String] as? String
            pairs["ModifyDate"]   = tiff[kCGImagePropertyTIFFDateTime as String] as? String
            pairs["HostComputer"] = tiff[kCGImagePropertyTIFFHostComputer as String] as? String
            pairs["ResolutionUnit"] = (tiff[kCGImagePropertyTIFFResolutionUnit as String] as? Int).map { $0 == 2 ? "inches" : "cm" }
            pairs["XResolution"]  = (tiff[kCGImagePropertyTIFFXResolution as String] as? Double).map { "\(Int($0))" }
            pairs["YResolution"]  = (tiff[kCGImagePropertyTIFFYResolution as String] as? Double).map { "\(Int($0))" }
        }
        
        // GPS
        if let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
            let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
            
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double {
                pairs["GPSLatitude"] = formatGPS(lat, ref: latRef)
            }
            if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
                pairs["GPSLongitude"] = formatGPS(lon, ref: lonRef)
            }
            if let alt = gps[kCGImagePropertyGPSAltitude as String] as? Double {
                let altRef = gps[kCGImagePropertyGPSAltitudeRef as String] as? Int ?? 0
                pairs["GPSAltitude"] = String(format: "%.1f m %@", alt, altRef == 0 ? "Above Sea Level" : "Below Sea Level")
            }
            pairs["GPSLatitudeRef"]  = latRef
            pairs["GPSLongitudeRef"] = lonRef
            pairs["GPSTimeStamp"]    = gps[kCGImagePropertyGPSTimeStamp as String] as? String
            pairs["GPSDateStamp"]    = gps[kCGImagePropertyGPSDateStamp as String] as? String
            pairs["GPSSpeed"]        = (gps[kCGImagePropertyGPSSpeed as String] as? Double).map { "\($0)" }
            pairs["GPSSpeedRef"]     = gps[kCGImagePropertyGPSSpeedRef as String] as? String
            pairs["GPSImgDirection"] = (gps[kCGImagePropertyGPSImgDirection as String] as? Double).map { String(format: "%.6f", $0) }
            pairs["GPSImgDirectionRef"] = gps[kCGImagePropertyGPSImgDirectionRef as String] as? String
            pairs["GPSDestBearing"]  = (gps[kCGImagePropertyGPSDestBearing as String] as? Double).map { String(format: "%.6f", $0) }
            pairs["GPSHPositioningError"] = (gps[kCGImagePropertyGPSHPositioningError as String] as? Double).map { String(format: "%.8f m", $0) }
            
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
                let latD = latRef == "S" ? -lat : lat
                let lonD = lonRef == "W" ? -lon : lon
                pairs["GPSPosition"] = String(format: "%.6f, %.6f", latD, lonD)
            }
        }
        
        // Apple MakerNote
        if let maker = props[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] {
            pairs["ContentIdentifier"]   = maker["17"] as? String
            pairs["LivePhotoVideoIndex"] = (maker["9"] as? Int).map { "\($0)" }
            pairs["HDRHeadroom"]         = (maker["33"] as? Double).map { String(format: "%.10f", $0) }
            pairs["ImageCaptureType"]    = (maker["6"] as? Int).map { "\($0)" }
        }
        
        // IPTC
        if let iptc = props[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
            pairs["Author"]   = iptc[kCGImagePropertyIPTCByline as String] as? String
            pairs["Keywords"] = (iptc[kCGImagePropertyIPTCKeywords as String] as? [String])?.joined(separator: ", ")
            pairs["Caption"]  = iptc[kCGImagePropertyIPTCCaptionAbstract as String] as? String
            pairs["City"]     = iptc[kCGImagePropertyIPTCCity as String] as? String
            pairs["Country"]  = iptc[kCGImagePropertyIPTCCountryPrimaryLocationName as String] as? String
        }
        
        // Remove nil values
        pairs = pairs.compactMapValues { $0 }
        
        return ExifMetadata(fileURL: url, raw: pairs)
    }
}

// MARK: - Formatters
extension NativeExtractor {
    private func formatExposure(_ value: Double) -> String {
        if value >= 1 { return String(format: "%.0f", value) }
        let denominator = Int(round(1.0 / value))
        return "1/\(denominator)"
    }

    private func formatGPS(_ decimal: Double, ref: String) -> String {
        let degrees = Int(decimal)
        let minutesDecimal = (decimal - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = (minutesDecimal - Double(minutes)) * 60
        return String(format: "%d deg %d' %.2f\" %@", degrees, minutes, seconds, ref)
    }
}
