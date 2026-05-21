# ExifToolKit

A Swift package for extracting EXIF metadata from images, videos, and documents on macOS. Supports native Apple APIs (ImageIO, AVFoundation, CoreGraphics) and system-installed ExifTool — no bundled binaries, fully notarizable, App Store compatible.

---

## Requirements

- macOS 13+
- Swift 5.9+
- Xcode 15+

---

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/saadtahir-dev/ExifToolKit.git", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["ExifToolKit"]
)
```

---

## Backends

ExifToolKit supports three backends, configured at init time.

### `.auto` (default)
Checks if ExifTool is installed on the system. If found, uses it for maximum tag coverage. If not, falls back to native Apple APIs automatically — no configuration required.

```swift
let tool = ExifTool() // backend: .auto
```

### `.native`
Uses Apple system frameworks exclusively — ImageIO for images, AVFoundation for audio/video, CoreGraphics for PDFs. Fully notarizable, App Store compatible, no external dependencies.

```swift
let tool = ExifTool(configuration: .init(backend: .native))
```

| Framework | File Types |
|---|---|
| ImageIO | JPEG, HEIC, HEIF, PNG, TIFF, RAW, DNG, CR2, NEF, ARW, and 40+ more |
| AVFoundation | MOV, MP4, M4V, M4A, MP3, AAC, FLAC, and more |
| CoreGraphics | PDF |

### `.exiftoolBinary`
Uses system-installed ExifTool (`brew install exiftool`) for maximum tag coverage including MakerNote fields, computed tags, and 20,000+ supported tags. Throws if ExifTool is not installed.

```swift
let tool = ExifTool(configuration: .init(backend: .exiftoolBinary))
```

---

## Usage

### Single file

```swift
import ExifToolKit

let tool = ExifTool()
let url  = URL(fileURLWithPath: "/path/to/image.heic")

let meta = try await tool.metadata(for: url)

print(meta.make)             // "Apple"
print(meta.model)            // "iPhone 11"
print(meta.iso)              // 200
print(meta.fNumber)          // 1.8
print(meta.focalLength)      // "4.2 mm"
print(meta.dateTimeOriginal) // Date
print(meta.gpsCoordinate)    // (31.455333, 74.276108)
print(meta.imageSize)        // (4032, 3024)

// Raw access for any tag
print(meta["LensModel"])     // "iPhone 11 back dual wide camera 4.25mm f/1.8"
print(meta["ContentIdentifier"]) // "D59008BC-DAC7-46D7-A576-8B510CE8D761"
```

### Specific tags (ExifTool binary only)

```swift
let meta = try await tool.metadata(for: url, tags: [.make, .model, .iso, .gpsLatitude])
```

### Batch processing

```swift
let urls: [URL] = [url1, url2, url3]
let results = try await tool.metadata(for: urls)
```

### Streaming — millions of files

For large-scale processing, `metadataStream` chunks files, processes them concurrently, and streams results without loading everything into memory.

```swift
let urls: [URL] = // millions of URLs

for await result in await tool.metadataStream(for: urls) {
    switch result {
    case .success(let meta):
        print(meta.make, meta.model)
    case .failure(let url, let error):
        print("Failed \(url.lastPathComponent): \(error)")
    }
}
```

### Custom configuration

```swift
let config = ExifTool.Configuration(
    backend: .auto,           // .native / .exiftoolBinary / .auto
    chunkSize: 1000,          // files per batch invocation
    maxConcurrency: 4,        // parallel workers
    numericOutput: false,     // pass -n to exiftool for raw numeric values
    executablePath: nil       // custom exiftool path, e.g. "/usr/local/bin/exiftool"
)
let tool = ExifTool(configuration: config)
```

### Check backend availability

```swift
let tool = ExifTool()
print(tool.isAvailable())          // always true (native is always present)
print(tool.isExiftoolInstalled())  // true if brew install exiftool was run
```

### Direct native extraction

```swift
let extractor = NativeExtractor()
let meta = try await extractor.extract(from: url)
```

---

## Supported Tags

### Typed accessors on `ExifMetadata`

| Property | Type | Description |
|---|---|---|
| `make` | `String?` | Camera manufacturer |
| `model` | `String?` | Camera model |
| `lensModel` | `String?` | Lens model |
| `iso` | `Int?` | ISO speed |
| `fNumber` | `Double?` | Aperture f-number |
| `exposureTime` | `String?` | Shutter speed (e.g. "1/50") |
| `focalLength` | `String?` | Focal length |
| `dateTimeOriginal` | `Date?` | Original capture date |
| `createDate` | `Date?` | Creation date |
| `gpsCoordinate` | `(latitude: Double, longitude: Double)?` | GPS decimal coordinates |
| `imageSize` | `(width: Int, height: Int)?` | Image dimensions |

### Tag constants via `ExifTag`

| Category | Tags |
|---|---|
| Camera | `.make`, `.model`, `.lensMake`, `.lensModel`, `.software` |
| Exposure | `.exposureTime`, `.fNumber`, `.iso`, `.focalLength`, `.flash`, `.meteringMode`, `.exposureProgram` |
| Date | `.dateTimeOriginal`, `.createDate`, `.modifyDate` |
| GPS | `.gpsLatitude`, `.gpsLongitude`, `.gpsAltitude` |
| Image | `.imageWidth`, `.imageHeight`, `.orientation`, `.colorSpace` |
| File | `.fileName`, `.fileSize`, `.mimeType`, `.fileType` |

Any tag not listed is accessible via raw string:

```swift
meta["HDRHeadroom"]
meta["ContentIdentifier"]
meta["LivePhotoVitalityScore"]
```

---

## Backend Comparison

| Feature | `.native` | `.exiftoolBinary` |
|---|---|---|
| Notarizable | ✅ | ✅ |
| App Store compatible | ✅ | ❌ |
| External dependency | None | `brew install exiftool` |
| Standard EXIF/GPS | ✅ | ✅ |
| Apple MakerNote | Partial | ✅ Full |
| Computed tags | ❌ | ✅ |
| 20,000+ tags | ❌ | ✅ |
| Images | ✅ 40+ formats | ✅ 100+ formats |
| Video | ✅ | ✅ |
| PDF | ✅ | ✅ |
| Audio | ✅ | ✅ |

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
