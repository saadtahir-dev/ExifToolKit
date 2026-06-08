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
import UniformTypeIdentifiers

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
        pairs["File Name"]  = url.lastPathComponent
        pairs["File Type"]  = url.pathExtension.uppercased()
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            pairs["File Size"] = "\(size) bytes"
        }
        if let uti = UTType(filenameExtension: url.pathExtension.lowercased()),
           let mime = uti.preferredMIMEType {
            pairs["MIME Type"] = mime
        }
        
        // Top-level image props
        if let width = props[kCGImagePropertyPixelWidth as String] as? Int {
            pairs["Image Width"] = "\(width)"
        }
        if let height = props[kCGImagePropertyPixelHeight as String] as? Int {
            pairs["Image Height"] = "\(height)"
        }
        if let depth = props[kCGImagePropertyDepth as String] as? Int {
            pairs["Bit Depth"] = "\(depth)"
        }
        if let orientation = props[kCGImagePropertyOrientation as String] as? Int {
            pairs["Orientation"] = NativeExtractor.orientationMap[orientation] ?? "\(orientation)"
        }
        if let dpi = props[kCGImagePropertyDPIWidth as String] as? Double {
            pairs["X Resolution"] = "\(Int(dpi))"
        }
        if let dpi = props[kCGImagePropertyDPIHeight as String] as? Double {
            pairs["Y Resolution"] = "\(Int(dpi))"
        }
        if let colorModel = props[kCGImagePropertyColorModel as String] as? String {
            pairs["Color Space"] = colorModel
        }
        if let profile = props[kCGImagePropertyProfileName as String] as? String {
            pairs["Profile Description"] = profile
        }
        
        // EXIF
        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            pairs["Exif Version"]                   = exif[kCGImagePropertyExifVersion as String] as? String
            pairs["Date/Time Original"]             = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String
            pairs["Create Date"]                    = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String
            pairs["Exposure Time"]                  = (exif[kCGImagePropertyExifExposureTime as String] as? Double).map { formatExposure($0) }
            pairs["F Number"]                       = (exif[kCGImagePropertyExifFNumber as String] as? Double).map { String(format: "%.1f", $0) }
            pairs["ISO"]                            = (exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first.map { "\($0)" }
            pairs["Shutter Speed Value"]            = (exif[kCGImagePropertyExifShutterSpeedValue as String] as? Double).map { String(format: "%.4f", $0) }
            pairs["Aperture Value"]                 = (exif[kCGImagePropertyExifApertureValue as String] as? Double).map { String(format: "%.1f", $0) }
            pairs["Brightness Value"]               = (exif[kCGImagePropertyExifBrightnessValue as String] as? Double).map { String(format: "%.6f", $0) }
            pairs["Exposure Compensation"]          = (exif[kCGImagePropertyExifExposureBiasValue as String] as? Double).map { "\($0)" }
            pairs["Metering Mode"]                  = (exif[kCGImagePropertyExifMeteringMode as String] as? Int).map { NativeExtractor.meteringModeMap[$0] ?? "\($0)" }
            pairs["Flash"]                          = (exif[kCGImagePropertyExifFlash as String] as? Int).map { NativeExtractor.flashMap[$0] ?? "\($0)" }
            pairs["Focal Length"]                   = (exif[kCGImagePropertyExifFocalLength as String] as? Double).map { String(format: "%.1f mm", $0) }
            pairs["Focal Length In 35mm Format"]    = (exif[kCGImagePropertyExifFocalLenIn35mmFilm as String] as? Int).map { "\($0) mm" }
            pairs["Exposure Program"]               = (exif[kCGImagePropertyExifExposureProgram as String] as? Int).map { NativeExtractor.exposureProgramMap[$0] ?? "\($0)" }
            pairs["White Balance"]                  = (exif[kCGImagePropertyExifWhiteBalance as String] as? Int).map { NativeExtractor.whiteBalanceMap[$0] ?? "\($0)" }
            pairs["Exif Image Width"]               = (exif[kCGImagePropertyExifPixelXDimension as String] as? Int).map { "\($0)" }
            pairs["Exif Image Height"]              = (exif[kCGImagePropertyExifPixelYDimension as String] as? Int).map { "\($0)" }
            pairs["Scene Type"]                     = (exif[kCGImagePropertyExifSceneType as String] as? Int).map { NativeExtractor.sceneTypeMap[$0] ?? "\($0)" }
            pairs["Exposure Mode"]                  = (exif[kCGImagePropertyExifExposureMode as String] as? Int).map { NativeExtractor.exposureModeMap[$0] ?? "\($0)" }
            pairs["Sensing Method"]                 = (exif[kCGImagePropertyExifSensingMethod as String] as? Int).map { NativeExtractor.sensingMethodMap[$0] ?? "\($0)" }
            pairs["Subject Area"]                   = (exif[kCGImagePropertyExifSubjectArea as String] as? [Int]).map { $0.map { "\($0)" }.joined(separator: " ") }
            pairs["Offset Time"]                    = exif[kCGImagePropertyExifOffsetTime as String] as? String
            pairs["Offset Time Original"]           = exif[kCGImagePropertyExifOffsetTimeOriginal as String] as? String
            pairs["Lens Info"]                      = (exif[kCGImagePropertyExifLensSpecification as String] as? [Double]).map { $0.map { String(format: "%.2f", $0) }.joined(separator: "-") }
            pairs["Lens Make"]                      = exif[kCGImagePropertyExifLensMake as String] as? String
            pairs["Lens Model"]                     = exif[kCGImagePropertyExifLensModel as String] as? String
            pairs["Sub Sec Time Original"]          = exif[kCGImagePropertyExifSubsecTimeOriginal as String] as? String
            pairs["Sub Sec Time Digitized"]         = exif[kCGImagePropertyExifSubsecTimeDigitized as String] as? String
        }
        
        // TIFF (Make, Model, Software etc.)
        if let tiff = props[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            pairs["Make"]               = tiff[kCGImagePropertyTIFFMake as String] as? String
            pairs["Camera Model Name"]  = tiff[kCGImagePropertyTIFFModel as String] as? String
            pairs["Software"]           = tiff[kCGImagePropertyTIFFSoftware as String] as? String
            pairs["Modify Date"]        = tiff[kCGImagePropertyTIFFDateTime as String] as? String
            pairs["Host Computer"]      = tiff[kCGImagePropertyTIFFHostComputer as String] as? String
            pairs["Resolution Unit"]    = (tiff[kCGImagePropertyTIFFResolutionUnit as String] as? Int).map { $0 == 2 ? "inches" : "cm" }
            pairs["X Resolution"]       = (tiff[kCGImagePropertyTIFFXResolution as String] as? Double).map { "\(Int($0))" }
            pairs["Y Resolution"]       = (tiff[kCGImagePropertyTIFFYResolution as String] as? Double).map { "\(Int($0))" }
            
            if let artist = tiff[kCGImagePropertyTIFFArtist as String] as? String, !artist.isEmpty {
                pairs["Author"] = artist
                pairs["Artist"] = artist
            }
        }
        
        // GPS
        if let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
            let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
            
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double {
                pairs["GPS Latitude"] = formatGPS(lat, ref: latRef)
            }
            
            if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
                pairs["GPS Longitude"] = formatGPS(lon, ref: lonRef)
            }
            
            if let alt = gps[kCGImagePropertyGPSAltitude as String] as? Double {
                let altRef = gps[kCGImagePropertyGPSAltitudeRef as String] as? Int ?? 0
                pairs["GPS Altitude"] = String(format: "%.1f m %@", alt, altRef == 0 ? "Above Sea Level" : "Below Sea Level")
            }
            
            pairs["GPS Latitude Ref"]                   = latRef == "N" ? "North" : "South"
            pairs["GPS Longitude Ref"]                  = lonRef == "E" ? "East" : "West"
            pairs["GPS Time Stamp"]                     = gps[kCGImagePropertyGPSTimeStamp as String] as? String
            pairs["GPS Date Stamp"]                     = gps[kCGImagePropertyGPSDateStamp as String] as? String
            pairs["GPS Speed"]                          = (gps[kCGImagePropertyGPSSpeed as String] as? Double).map { "\($0)" }
            pairs["GPS Speed Ref"]                      = (gps[kCGImagePropertyGPSSpeedRef as String] as? String).map { NativeExtractor.gpsSpeedRefMap[$0] ?? $0 }
            pairs["GPS Img Direction"]                  = (gps[kCGImagePropertyGPSImgDirection as String] as? Double).map { String(format: "%.6f", $0) }
            pairs["GPS Img Direction Ref"]              = (gps[kCGImagePropertyGPSImgDirectionRef as String] as? String).map { NativeExtractor.gpsDirectionRefMap[$0] ?? $0 }
            pairs["GPS Dest Bearing"]                   = (gps[kCGImagePropertyGPSDestBearing as String] as? Double).map { String(format: "%.6f", $0) }
            pairs["GPS Horizontal Positioning Error"]   = (gps[kCGImagePropertyGPSHPositioningError as String] as? Double).map { String(format: "%.8f m", $0) }
            
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
                let latD = latRef == "S" ? -lat : lat
                let lonD = lonRef == "W" ? -lon : lon
                pairs["GPS Position"] = String(format: "%.6f, %.6f", latD, lonD)
            }
        }
        
        // Apple MakerNote
        if let maker = props[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] {
            pairs["Content Identifier"]     = maker["17"] as? String
            pairs["Live Photo Video Index"] = (maker["9"] as? Int).map { "\($0)" }
            pairs["HDR Headroom"]           = (maker["33"] as? Double).map { String(format: "%.10f", $0) }
            pairs["Image Capture Type"]     = (maker["6"] as? Int).map { "\($0)" }
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
