//
//  NativeExtractor+AVFoundation.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation
import AVFoundation
import CoreLocation

extension NativeExtractor {
    func extractAudioVideo(from url: URL) async throws -> ExifMetadata {
        let asset = AVAsset(url: url)
        var pairs: [String: String] = [:]

        // File info
        pairs["File Name"] = url.lastPathComponent
        pairs["File Type"] = url.pathExtension.uppercased()
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            pairs["File Size"] = "\(size) bytes"
        }
        if let uti = UTType(filenameExtension: url.pathExtension.lowercased()),
           let mime = uti.preferredMIMEType {
            pairs["MIME Type"] = mime
        }

        // Duration
        if let duration = try? await asset.load(.duration),
           duration.isValid && !duration.isIndefinite {
            pairs["Duration"] = String(format: "%.2f s", CMTimeGetSeconds(duration))
        }

        // Tracks
        if let tracks = try? await asset.load(.tracks) {
            for track in tracks {
                switch track.mediaType {
                case .video:
                    if let descs = try? await track.load(.formatDescriptions),
                       let first = descs.first {
                        let dimensions = CMVideoFormatDescriptionGetDimensions(first)
                        if dimensions.width > 0 && dimensions.height > 0 {
                            pairs["Image Width"]  = "\(dimensions.width)"
                            pairs["Image Height"] = "\(dimensions.height)"
                        }
                        let sub = CMFormatDescriptionGetMediaSubType(first)
                        let codec = String(format: "%c%c%c%c",
                            (sub >> 24) & 0xFF, (sub >> 16) & 0xFF,
                            (sub >> 8)  & 0xFF,  sub & 0xFF)
                        pairs["Compressor ID"] = codec.trimmingCharacters(in: .whitespaces)
                    } else if let size = try? await track.load(.naturalSize) {
                        pairs["Image Width"]  = "\(Int(size.width))"
                        pairs["Image Height"] = "\(Int(size.height))"
                    }
                    if let fps = try? await track.load(.nominalFrameRate) {
                        pairs["Video Frame Rate"] = String(format: "%.3f", fps)
                    }
                    if let rate = try? await track.load(.estimatedDataRate), rate > 0 {
                        pairs["Avg Bitrate"] = String(format: "%.1f Mbps", rate / 1_000_000)
                    }
                    pairs["Bit Depth"] = "24"

                case .audio:
                    if let descs = try? await track.load(.formatDescriptions) {
                        pairs["Audio Channels"] = "\(descs.count)"
                        if let first = descs.first {
                            let sub = CMFormatDescriptionGetMediaSubType(first)
                            let codec = String(format: "%c%c%c%c",
                                (sub >> 24) & 0xFF, (sub >> 16) & 0xFF,
                                (sub >> 8)  & 0xFF,  sub & 0xFF)
                            pairs["Audio Format"] = codec.trimmingCharacters(in: .whitespaces)
                        }
                    }

                default:
                    break
                }
            }
        }

        // Metadata
        if let allMetadata = try? await asset.load(.metadata) {
            for item in allMetadata {
                guard let key = item.commonKey?.rawValue ?? (item.key as? String) else { continue }
                let strValue = try? await item.load(.stringValue)
                let numValue = try? await item.load(.numberValue)
                let value    = strValue ?? numValue?.stringValue ?? ""
                guard !value.isEmpty else { continue }

                switch key {
                case AVMetadataKey.commonKeyMake.rawValue,
                     "com.apple.quicktime.make":
                    pairs["Make"] = value
                    
                case AVMetadataKey.commonKeyModel.rawValue,
                     "com.apple.quicktime.model":
                    pairs["Camera Model Name"] = value
                    
                case AVMetadataKey.commonKeySoftware.rawValue,
                     "com.apple.quicktime.software":
                    pairs["Software"] = value
                    
                case AVMetadataKey.commonKeyCreationDate.rawValue,
                     "com.apple.quicktime.creationdate":
                    pairs["Creation Date"] = value
                    
                case AVMetadataKey.commonKeyLocation.rawValue,
                     "com.apple.quicktime.location.ISO6709":
                    parseISO6709(value, into: &pairs)
                    
                case AVMetadataKey.commonKeyAuthor.rawValue,
                     "com.apple.quicktime.author":
                    pairs["Author"] = value
                    
                case AVMetadataKey.commonKeyArtist.rawValue,
                     "com.apple.quicktime.artist":
                    if pairs["Author"] == nil {
                        pairs["Author"] = value
                    }
                    pairs["Artist"] = value
                    
                case AVMetadataKey.commonKeyContributor.rawValue:
                    pairs["Contributor"] = value
                    
                case AVMetadataKey.commonKeyPublisher.rawValue:
                    pairs["Publisher"] = value
                    
                case "com.apple.quicktime.content.identifier":
                    pairs["Content Identifier"] = value
                    
                case "com.apple.quicktime.live-photo.auto":
                    pairs["Live Photo Auto"] = value
                    
                case "com.apple.quicktime.camera.lens_model",
                     "com.apple.quicktime.camera.lens_model-und-CA":
                    pairs["Camera Lens Model"] = value
                    
                case "com.apple.quicktime.camera.focal_length.35mm_equivalent":
                    pairs["Camera Focal Length 35mm Equivalent"] = value
                    
                case "com.apple.quicktime.live-photo.vitality-score":
                    pairs["Live Photo Vitality Score"] = value
                    
                case AVMetadataKey.commonKeyTitle.rawValue:
                    pairs["Title"] = value
                    
                case AVMetadataKey.commonKeyDescription.rawValue:
                    pairs["Description"] = value
                    
                case AVMetadataKey.commonKeySubject.rawValue:
                    pairs["Subject"] = value
                    
                default:
                    break
                }
            }
        }

        // Creation date fallback
        if pairs["Creation Date"] == nil,
           let metaItem = try? await asset.load(.creationDate),
           let date     = try? await metaItem.load(.dateValue) {
            pairs["Creation Date"] = ISO8601DateFormatter().string(from: date)
        }

        pairs = pairs.compactMapValues { $0 }
        return ExifMetadata(fileURL: url, raw: pairs)
    }
}

// MARK: - ISO 6709 GPS Parser
extension NativeExtractor {
    private func parseISO6709(_ value: String, into pairs: inout [String: String]) {
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "")
        guard cleaned.count >= 8 else { return }

        var str        = cleaned
        var components = [Double]()

        while !str.isEmpty {
            guard let sign = str.first, sign == "+" || sign == "-" else { break }
            str.removeFirst()
            let digits = str.prefix(while: { $0.isNumber || $0 == "." })
            if let val = Double(digits) {
                components.append(sign == "-" ? -val : val)
            }
            str.removeFirst(digits.count)
        }

        guard components.count >= 2 else { return }

        let lat    = components[0]
        let lon    = components[1]
        let latRef = lat >= 0 ? "N" : "S"
        let lonRef = lon >= 0 ? "E" : "W"

        pairs["GPS Latitude"]      = formatGPSDecimal(abs(lat), ref: latRef)
        pairs["GPS Longitude"]     = formatGPSDecimal(abs(lon), ref: lonRef)
        pairs["GPS Latitude Ref"]  = lat >= 0 ? "North" : "South"
        pairs["GPS Longitude Ref"] = lon >= 0 ? "East" : "West"
        pairs["GPS Position"]      = String(format: "%.6f, %.6f", lat, lon)

        if components.count >= 3 {
            let alt = components[2]
            pairs["GPS Altitude"]     = String(format: "%.3f m", alt)
            pairs["GPS Altitude Ref"] = alt >= 0 ? "Above Sea Level" : "Below Sea Level"
        }
    }

    private func formatGPSDecimal(_ decimal: Double, ref: String) -> String {
        let degrees        = Int(decimal)
        let minutesDecimal = (decimal - Double(degrees)) * 60
        let minutes        = Int(minutesDecimal)
        let seconds        = (minutesDecimal - Double(minutes)) * 60
        return String(format: "%d deg %d' %.2f\" %@", degrees, minutes, seconds, ref)
    }
}
