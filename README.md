# MusaveraKit

One-line Swift APIs for Apple's `MusicUnderstanding.framework`.

MusaveraKit is the music-intelligence sibling to MusadoraKit. Where MusadoraKit makes MusicKit and the Apple Music API easier to use, MusaveraKit makes Apple's new MusicUnderstanding framework easier to use.

```swift
import AVFoundation
import MusaveraKit

let asset = AVURLAsset(url: songURL)
let analysis = try await Musavera.analyze(asset: asset)

print(analysis.beatsPerMinute)
print(analysis.key?.primarySignature?.musaveraDescription)
print(analysis.structure?.sections)
print(analysis.instrumentActivity?.vocalRanges)
```

## Requirements

- Xcode 27 beta
- Swift 6.4 toolchain
- iOS 27.0+
- macOS 27.0+
- tvOS 27.0+
- watchOS 27.0+
- visionOS 27.0+

`MusicUnderstanding.framework` is currently available in the Xcode 27 beta SDK.

## What It Wraps

MusaveraKit sits on top of:

```swift
MusicUnderstandingSession
AnalysisType
RhythmResult
KeyResult
LoudnessResult
PaceResult
StructureResult
InstrumentActivityResult
```

## One-Line APIs

Analyze everything:

```swift
let analysis = try await Musavera.analyze(asset: asset)
```

Analyze selected dimensions:

```swift
let analysis = try await Musavera.analyze(
    asset: asset,
    options: [.rhythm, .key, .structure]
)
```

Fetch focused results:

```swift
let rhythm = try await Musavera.rhythm(for: asset)
let key = try await Musavera.key(for: asset)
let loudness = try await Musavera.loudness(for: asset)
let pace = try await Musavera.pace(for: asset)
let structure = try await Musavera.structure(for: asset)
let instruments = try await Musavera.instrumentActivity(for: asset)
```

## Convenience Helpers

```swift
analysis.beatsPerMinute
analysis.beatCount
analysis.barCount
analysis.sectionCount
analysis.keySignature(at: time)
```

```swift
key.primarySignature?.musaveraDescription
key.signature(at: time)
```

```swift
rhythm.nearestBeat(to: time)
rhythm.nearestBar(to: time)
```

```swift
structure.section(containing: time)
structure.phrase(containing: time)
structure.segment(containing: time)
```

```swift
instruments.vocalRanges
instruments.drumRanges
instruments.bassRanges
instruments.otherRanges
```

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/rryam/MusaveraKit.git", branch: "main")
]
```

```swift
.product(name: "MusaveraKit", package: "MusaveraKit")
```

## Musavera Lab

[`Examples/MusaveraLab`](Examples/MusaveraLab) is a signed macOS 27 sample app
that composes first-party MusicKit with MusaveraKit. It searches Apple Music,
shows catalog artwork, downloads a song's 30-second preview for local analysis,
offers separate full-song playback, and renders synchronized key, rhythm,
structure, pace, instrument, and loudness views.

The activity charts adapt from one to four columns, so a large window can show
all four instrument activity timelines side by side.

## Current Status

This is a beta SDK package. It is intentionally small and compiler-first while Apple finishes documenting the MusicUnderstanding framework.

The first version focuses on:

- clean one-line analysis calls
- focused helpers for each result type
- timeline-friendly convenience APIs
- testable option/result helpers

## Build

```bash
DEVELOPER_DIR=/Users/rudrank/Downloads/Xcode-beta.app/Contents/Developer \
xcodebuild -scheme MusaveraKit \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ./.build/xcode \
  build
```

`swift test` currently compiles the package, but cannot run on a Mac that does not have the macOS 27 `MusicUnderstanding.framework` runtime installed in `/System/Library/Frameworks`.
