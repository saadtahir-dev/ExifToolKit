//
//  ExifToolKitTests.swift
//  ExifToolKit
//
//  Created by Saad Tahir on 21/05/2026.
//   -- GitHub   : https://github.com/saadtahir-dev
//   -- LinkedIn : https://www.linkedin.com/in/saadtahir-dev
//

import Foundation
import Testing
@testable import ExifToolKit
import UniformTypeIdentifiers

@Suite("ExifToolKit Tests")
struct ExifToolKitTests {

    let heicURL = URL(fileURLWithPath: "/Users/saadtahir/Documents/_LAB_Output/1_2026-05-20T14-42-54/Indexed Sources/Duplicate-000A6D400EDA802E/Extracted Backup/CameraRollDomain/Media/DCIM/100APPLE/IMG_0003.HEIC")
    let movURL  = URL(fileURLWithPath: "/Users/saadtahir/Documents/_LAB_Output/1_2026-05-20T14-42-54/Indexed Sources/Duplicate-000A6D400EDA802E/Extracted Backup/CameraRollDomain/Media/DCIM/100APPLE/IMG_0001.MOV")

    // MARK: - ExifTool Binary

    @Test("ExifTool binary is available")
    func isAvailable() async {
        let tool = ExifTool()
        #expect(await tool.isAvailable() == true)
    }

    @Test("Missing file throws fileNotFound")
    func missingFileThrows() async {
        let tool = ExifTool()
        let url  = URL(fileURLWithPath: "/tmp/nonexistent.jpg")
        do {
            _ = try await tool.metadata(for: url)
            Issue.record("Expected error not thrown")
        } catch ExifToolError.fileNotFound(let path) {
            #expect(path == "/tmp/nonexistent.jpg")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Empty URL array returns empty results")
    func emptyURLsReturnsEmpty() async {
        let tool = ExifTool()
        do {
            let results = try await tool.metadata(for: [])
            #expect(results.isEmpty)
        } catch ExifToolError.processFailure {
            // expected — exiftool exits 2 with no files
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Stream

    @Test("metadataStream finishes for empty input")
    func streamFinishesOnEmpty() async {
        let stream = await ExifTool().metadataStream(for: [])
        var count  = 0
        for await _ in stream { count += 1 }
        #expect(count == 0)
    }

    @Test("metadataStream yields failure for missing files")
    func streamYieldsFailureForMissingFiles() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/missing1.jpg"),
            URL(fileURLWithPath: "/tmp/missing2.jpg"),
        ]
        let stream   = await ExifTool().metadataStream(for: urls, chunkSize: 2)
        var failures = 0
        for await result in stream {
            if case .failure = result { failures += 1 }
        }
        #expect(failures == urls.count)
    }

    // MARK: - Native: Type Routing

    @Test("NativeExtractor routes HEIC as image")
    func routingHEIC() {
        let extractor = NativeExtractor()
        let uti = UTType(filenameExtension: "heic")
        #expect(extractor.isImage(uti, ext: "heic") == true)
        #expect(extractor.isAudioVideo(uti, ext: "heic") == false)
        #expect(extractor.isPDF(uti, ext: "heic") == false)
    }

    @Test("NativeExtractor routes MOV as audio/video")
    func routingMOV() {
        let extractor = NativeExtractor()
        let uti = UTType(filenameExtension: "mov")
        #expect(extractor.isAudioVideo(uti, ext: "mov") == true)
        #expect(extractor.isImage(uti, ext: "mov") == false)
    }

    @Test("NativeExtractor routes PDF")
    func routingPDF() {
        let extractor = NativeExtractor()
        let uti = UTType(filenameExtension: "pdf")
        #expect(extractor.isPDF(uti, ext: "pdf") == true)
        #expect(extractor.isImage(uti, ext: "pdf") == false)
    }

    @Test("NativeExtractor routes unknown extension via fallback")
    func routingFallback() {
        let extractor = NativeExtractor()
        #expect(extractor.isImage(nil, ext: "cr2") == true)
        #expect(extractor.isImage(nil, ext: "dng") == true)
        #expect(extractor.isAudioVideo(nil, ext: "flac") == true)
        #expect(extractor.isAudioVideo(nil, ext: "mkv") == true)
        #expect(extractor.isPDF(nil, ext: "pdf") == true)
    }

    // MARK: - Native: HEIC

    @Test("Native HEIC - camera metadata")
    func nativeHEICCamera() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        #expect(meta.make == "Apple")
        #expect(meta.model == "iPhone 11")
        #expect(meta.iso == 200)
        #expect(meta.fNumber == 1.8)
        #expect(meta.raw["LensModel"] == "iPhone 11 back dual wide camera 4.25mm f/1.8")
        #expect(meta.raw["Software"] == "18.6")
    }

    @Test("Native HEIC - exposure metadata")
    func nativeHEICExposure() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        #expect(meta.raw["ExposureTime"] == "1/50")
        #expect(meta.raw["FocalLength"] != nil)
        #expect(meta.raw["FocalLengthIn35mmFormat"] != nil)
        #expect(meta.raw["Flash"] != nil)
        #expect(meta.raw["MeteringMode"] != nil)
    }

    @Test("Native HEIC - GPS metadata")
    func nativeHEICGPS() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        #expect(meta.gpsCoordinate != nil)
        #expect(meta.raw["GPSLatitude"] != nil)
        #expect(meta.raw["GPSLongitude"] != nil)
        #expect(meta.raw["GPSAltitude"] != nil)
        #expect(meta.raw["GPSLatitudeRef"] == "N")
        #expect(meta.raw["GPSLongitudeRef"] == "E")
        if let coord = meta.gpsCoordinate {
            #expect(coord.latitude  > 31.0 && coord.latitude  < 32.0)
            #expect(coord.longitude > 74.0 && coord.longitude < 75.0)
        }
    }

    @Test("Native HEIC - date metadata")
    func nativeHEICDates() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        #expect(meta.raw["DateTimeOriginal"] == "2026:01:27 14:05:00")
        #expect(meta.raw["CreateDate"] != nil)
        #expect(meta.raw["ModifyDate"] != nil)
    }

    @Test("Native HEIC - image dimensions")
    func nativeHEICDimensions() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        #expect(meta.imageSize?.width  == 4032)
        #expect(meta.imageSize?.height == 3024)
    }

    @Test("Native HEIC - Apple MakerNote")
    func nativeHEICMakerNote() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        #expect(meta.raw["ContentIdentifier"] == "D59008BC-DAC7-46D7-A576-8B510CE8D761")
        #expect(meta.raw["HDRHeadroom"] != nil)
    }

    // MARK: - Native: MOV

    @Test("Native MOV - camera metadata")
    func nativeMOVCamera() async throws {
        guard FileManager.default.fileExists(atPath: movURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: movURL)
        #expect(meta.make == "Apple")
        #expect(meta.model == "iPhone 11")
        #expect(meta.raw["Software"] == "18.6")
    }

    @Test("Native MOV - video track metadata")
    func nativeMOVVideo() async throws {
        guard FileManager.default.fileExists(atPath: movURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: movURL)
        #expect(meta.raw["ImageWidth"]     == "1920")
        #expect(meta.raw["ImageHeight"]    == "1440")
        #expect(meta.raw["VideoFrameRate"] != nil)
        #expect(meta.raw["Duration"]       != nil)
        #expect(meta.raw["CompressorID"]   != nil)
    }

    @Test("Native MOV - GPS metadata")
    func nativeMOVGPS() async throws {
        guard FileManager.default.fileExists(atPath: movURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: movURL)
        #expect(meta.raw["GPSLatitude"]  != nil)
        #expect(meta.raw["GPSLongitude"] != nil)
        #expect(meta.raw["GPSAltitude"]  != nil)
    }

    @Test("Native MOV - creation date")
    func nativeMOVDate() async throws {
        guard FileManager.default.fileExists(atPath: movURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: movURL)
        #expect(meta.raw["CreationDate"] != nil)
    }

    // MARK: - Native: print all tags

    @Test("Print all HEIC tags")
    func printAllHEICTags() async throws {
        guard FileManager.default.fileExists(atPath: heicURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: heicURL)
        print("\n=== HEIC (\(meta.raw.count) tags) ===")
        for (k, v) in meta.raw.sorted(by: { $0.key < $1.key }) {
            print("  \(k): \(v)")
        }
    }

    @Test("Print all MOV tags")
    func printAllMOVTags() async throws {
        guard FileManager.default.fileExists(atPath: movURL.path) else { return }
        let meta = try await NativeExtractor().extract(from: movURL)
        print("\n=== MOV (\(meta.raw.count) tags) ===")
        for (k, v) in meta.raw.sorted(by: { $0.key < $1.key }) {
            print("  \(k): \(v)")
        }
    }
}
