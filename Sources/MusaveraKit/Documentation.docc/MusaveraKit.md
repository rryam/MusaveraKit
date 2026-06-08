# ``MusaveraKit``

Use one-line APIs to analyze music rhythm, key, loudness, pace, structure, and instrument activity.

## Overview

MusaveraKit wraps Apple's `MusicUnderstanding.framework` with a small app-friendly API.

```swift
let analysis = try await Musavera.analyze(asset: asset)
```

## Topics

### Analysis

- ``Musavera``
- ``MusaveraAnalysis``
- ``MusaveraAnalysisOptions``

### Errors

- ``MusaveraKitError``
