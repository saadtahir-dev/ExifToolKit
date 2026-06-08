//
//  NativeExtractor+DecodeMaps.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 08/06/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

// MARK: - Decode Maps
extension NativeExtractor {
    static let orientationMap: [Int: String] = [
        1: "Horizontal (normal)",
        2: "Mirror horizontal",
        3: "Rotate 180",
        4: "Mirror vertical",
        5: "Mirror horizontal and rotate 270 CW",
        6: "Rotate 90 CW",
        7: "Mirror horizontal and rotate 90 CW",
        8: "Rotate 270 CW"
    ]

    static let flashMap: [Int: String] = [
        0x0:  "No Flash",
        0x1:  "Fired",
        0x5:  "Fired, Return not detected",
        0x7:  "Fired, Return detected",
        0x8:  "On, Did not fire",
        0x9:  "On, Fired",
        0xd:  "On, Return not detected",
        0xf:  "On, Return detected",
        0x10: "Off, Did not fire",
        0x14: "Off, Did not fire, Return not detected",
        0x18: "Auto, Did not fire",
        0x19: "Auto, Fired",
        0x1d: "Auto, Fired, Return not detected",
        0x1f: "Auto, Fired, Return detected",
        0x20: "No flash function",
        0x30: "Off, No flash function",
        0x41: "Fired, Red-eye reduction",
        0x45: "Fired, Red-eye reduction, Return not detected",
        0x47: "Fired, Red-eye reduction, Return detected",
        0x49: "On, Red-eye reduction",
        0x4d: "On, Red-eye reduction, Return not detected",
        0x4f: "On, Red-eye reduction, Return detected",
        0x50: "Off, Red-eye reduction",
        0x58: "Auto, Did not fire, Red-eye reduction",
        0x59: "Auto, Fired, Red-eye reduction",
        0x5d: "Auto, Fired, Red-eye reduction, Return not detected",
        0x5f: "Auto, Fired, Red-eye reduction, Return detected"
    ]

    static let exposureProgramMap: [Int: String] = [
        0: "Not Defined",
        1: "Manual",
        2: "Program AE",
        3: "Aperture-priority AE",
        4: "Shutter speed priority AE",
        5: "Creative (Slow speed)",
        6: "Action (High speed)",
        7: "Portrait",
        8: "Landscape"
    ]

    static let meteringModeMap: [Int: String] = [
        0: "Unknown",
        1: "Average",
        2: "Center-weighted average",
        3: "Spot",
        4: "Multi-spot",
        5: "Multi-segment",
        6: "Partial",
        255: "Other"
    ]

    static let exposureModeMap: [Int: String] = [
        0: "Auto",
        1: "Manual",
        2: "Auto bracket"
    ]

    static let whiteBalanceMap: [Int: String] = [
        0: "Auto",
        1: "Manual"
    ]

    static let sceneTypeMap: [Int: String] = [
        1: "Directly photographed"
    ]

    static let sensingMethodMap: [Int: String] = [
        1: "Not defined",
        2: "One-chip color area",
        3: "Two-chip color area",
        4: "Three-chip color area",
        5: "Color sequential area",
        7: "Trilinear",
        8: "Color sequential linear"
    ]

    static let gpsSpeedRefMap: [String: String] = [
        "K": "km/h",
        "M": "mph",
        "N": "knots"
    ]

    static let gpsDirectionRefMap: [String: String] = [
        "T": "True North",
        "M": "Magnetic North"
    ]
}

// MARK: - MIME Type
public extension NativeExtractor {
    static let mimeTypeFallbackMap: [String: String] = [
        // Image formats not covered by UTType
        "cur":  "image/vnd.microsoft.icon",
        "jpm":  "image/jpm",
        "x3f":  "image/x-sigma-x3f",
        
        // Audio/Video formats not covered by UTType
        "m2ts": "video/mp2t",
        "m4b":  "audio/mp4",
        "mkv":  "video/x-matroska",
        "mts":  "video/mp2t",
        "ts":   "video/mp2t",
        
        // Common app/system formats
        "plist":   "application/x-plist",
        "bplist":  "application/x-plist",
        "db":      "application/x-sqlite3",
        "sqlite":  "application/x-sqlite3",
        "sqlite3": "application/x-sqlite3",
        "ipa":     "application/octet-stream",
        "dylib":   "application/octet-stream",
        "strings": "text/plain",
        "nib":     "application/octet-stream",
        "car":     "application/octet-stream",
    ]
}
