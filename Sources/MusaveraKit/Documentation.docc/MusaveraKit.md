# ``MusaveraKit``

Analyze rhythm, key, loudness, pace, structure, and instrument activity with a
small API built on Music Understanding.

## Overview

MusaveraKit creates and runs ``MusicUnderstandingSession`` instances for audio
assets, then presents the result through ``MusaveraAnalysis``.

```swift
import AVFoundation
import MusaveraKit

let asset = AVURLAsset(url: audioURL)
let analysis = try await Musavera.analyze(asset: asset)
```

Request every analysis type, select only the dimensions your app needs, or use
a focused helper that returns an Apple result type directly.

MusaveraKit also adds timeline-oriented conveniences for finding the current
key or structure range, locating nearby beats and bars, and accessing
instrument ranges.

> Important: Music Understanding is a beta framework. MusaveraKit requires
> Xcode 27 and version 27 or later of each supported Apple platform.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:AnalysisResults>

### Starting Analysis

- ``Musavera``
- ``Musavera/analyze(asset:)``
- ``Musavera/analyze(asset:options:)``
- ``MusaveraAnalysisOptions``

### Results and Errors

- ``MusaveraAnalysis``
- ``MusaveraKitError``
