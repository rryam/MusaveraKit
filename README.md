# MusaveraKit

Small, app-friendly Swift APIs for on-device music analysis with Apple's
[Music Understanding](https://developer.apple.com/documentation/MusicUnderstanding)
framework.

[![Repository checks](https://github.com/rryam/MusaveraKit/actions/workflows/repository-checks.yml/badge.svg)](https://github.com/rryam/MusaveraKit/actions/workflows/repository-checks.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138.svg?logo=swift&logoColor=white)](https://www.swift.org)
[![Apple platforms 27+](https://img.shields.io/badge/Apple%20platforms-27%2B-000000.svg?logo=apple&logoColor=white)](#requirements)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```swift
import AVFoundation
import MusaveraKit

let asset = AVURLAsset(url: audioURL)
let analysis = try await Musavera.analyze(asset: asset)

print(analysis.beatsPerMinute as Any)
print(analysis.key?.primarySignature?.musaveraDescription as Any)
print(analysis.sectionCount)
```

MusaveraKit keeps Music Understanding's native result types available while
removing repetition around session setup, focused analysis, optional results,
and common timeline lookups.

## Early Access

Music Understanding was introduced at WWDC26 and remains a beta framework.
MusaveraKit tracks that SDK closely, so APIs and platform requirements may
change during the beta cycle.

Full compilation and runtime testing require Xcode 27 and an operating-system
27 runtime. GitHub's current hosted runners do not include that SDK, so CI
performs repository, manifest, privacy, and Swift syntax validation. Complete
builds and tests are run locally with Xcode 27.

## Requirements

- Xcode 27 beta or later
- Swift 6.4 or later
- iOS 27.0+
- macOS 27.0+
- tvOS 27.0+
- watchOS 27.0+
- visionOS 27.0+

## Installation

Add MusaveraKit with Swift Package Manager:

```swift
dependencies: [
    .package(
        url: "https://github.com/rryam/MusaveraKit.git",
        from: "0.2.1"
    )
]
```

Then add the product to your target:

```swift
.product(name: "MusaveraKit", package: "MusaveraKit")
```

## Analyze Audio

Create an `AVAsset` for audio your app can access, then request all supported
analysis:

```swift
let asset = AVURLAsset(url: audioURL)
let analysis = try await Musavera.analyze(asset: asset)
```

The returned `MusaveraAnalysis` exposes Music Understanding's session result
and convenient accessors for:

- rhythm, beats, bars, and beats per minute
- musical key
- loudness
- perceived pace
- sections, phrases, and segments
- vocal, drum, bass, and other instrument activity

Music Understanding performs its analysis on device. MusaveraKit does not
upload audio, download Apple Music content, or require MusadoraKit.

## Request Only What You Need

Selected analysis avoids unnecessary work:

```swift
let analysis = try await Musavera.analyze(
    asset: asset,
    options: [.rhythm, .key, .structure]
)
```

Use a focused helper when one result is enough:

```swift
let rhythm = try await Musavera.rhythm(for: asset)
let key = try await Musavera.key(for: asset)
let loudness = try await Musavera.loudness(for: asset)
let pace = try await Musavera.pace(for: asset)
let structure = try await Musavera.structure(for: asset)
let instruments = try await Musavera.instrumentActivity(for: asset)
```

Passing an empty option set throws `MusaveraKitError.emptyAnalysisSet`. A
focused helper throws `MusaveraKitError.missingResult` if the framework does not
return its requested result.

## Analyze Streaming Audio

Create a session from any nonthrowing asynchronous sequence of read-only PCM
buffers:

```swift
let session = MusaveraStreamingSession(audioProvider: audioBuffers)

async let analysis = session.analyze()

for try await loudness in session.loudnessResults {
    updateMeter(with: loudness)
}

let completedAnalysis = try await analysis
```

Loudness results arrive while the provider yields audio. The complete
`MusaveraAnalysis`, including key, rhythm, structure, pace, and instrument
activity, becomes available after the provider finishes.

## Timeline Helpers

MusaveraKit adds small conveniences for playback-synchronized interfaces:

```swift
let signature = analysis.keySignature(at: playbackTime)
let nearestBeat = rhythm.nearestBeat(to: playbackTime)
let nearestBar = rhythm.nearestBar(to: playbackTime)

let section = structure.section(containing: playbackTime)
let phrase = structure.phrase(containing: playbackTime)
let segment = structure.segment(containing: playbackTime)
```

Instrument activity is available as both detected ranges and timed values:

```swift
let vocalRanges = instruments.vocalRanges
let drumRanges = instruments.drumRanges
let bassRanges = instruments.bassRanges
let otherRanges = instruments.otherRanges

let vocalActivity = instruments.activity(for: .vocal)
```

## MusadoraKit and MusaveraKit

[MusadoraKit](https://github.com/rryam/MusadoraKit) simplifies MusicKit and
Apple Music API workflows such as catalog search, library access, and playback.
MusaveraKit analyzes audio assets for musical characteristics. The packages are
independent so apps can adopt either one, while remaining complementary for
music discovery, playback, and visualization experiences.

## Musavera Lab

[`Examples/MusaveraLab`](Examples/MusaveraLab) is a signed macOS 27 sample app
that composes first-party MusicKit with MusaveraKit. It searches Apple Music,
shows catalog artwork, downloads a song's 30-second preview for local analysis,
offers separate full-song playback, and renders synchronized key, rhythm,
structure, pace, instrument, and loudness views. The complete native
MusicUnderstanding result can also be exported as formatted JSON. Its Live
Stream workspace analyzes microphone PCM, draws realtime loudness, and
completes the remaining musical analysis when capture stops.

The activity charts adapt from one to four columns, so a large window can show
all four instrument activity timelines side by side.

## Development

Select Xcode 27 if it is not already active:

```bash
export DEVELOPER_DIR=/path/to/Xcode-beta.app/Contents/Developer
```

Run the complete test suite:

```bash
swift test
```

Build an Apple-platform target:

```bash
xcodebuild \
  -scheme MusaveraKit \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/xcode \
  build
```

Run checks that also work before the Xcode 27 SDK is available:

```bash
Scripts/validate-repository.sh
```

Generate DocC documentation:

```bash
swift package generate-documentation \
  --target MusaveraKit \
  Sources/MusaveraKit/Documentation.docc
```

## Documentation and Resources

- [Getting Started](Sources/MusaveraKit/Documentation.docc/GettingStarted.md)
- [Working with Analysis Results](Sources/MusaveraKit/Documentation.docc/AnalysisResults.md)
- [Music Understanding documentation](https://developer.apple.com/documentation/MusicUnderstanding)
- [Meet the Music Understanding framework](https://developer.apple.com/videos/play/wwdc2026/253/)
- [Creating visuals using analysis results](https://developer.apple.com/documentation/MusicUnderstanding/create-visuals-using-musicunderstanding-analysis-results)

## Project Policies

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing a change.
- Use [SUPPORT.md](SUPPORT.md) to choose the right reporting channel.
- Report vulnerabilities according to [SECURITY.md](SECURITY.md).
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- See [CONTRIBUTORS.md](CONTRIBUTORS.md) for project attribution.
- Review [CHANGELOG.md](CHANGELOG.md) for notable changes.

## License

MusaveraKit is available under the MIT License. See [LICENSE](LICENSE).

Apple, Apple Music, MusicKit, and related marks are trademarks of Apple Inc.
MusaveraKit is an independent open-source project and is not affiliated with or
endorsed by Apple.
