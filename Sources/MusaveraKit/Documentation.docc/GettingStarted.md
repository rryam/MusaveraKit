# Getting Started

Create an audio asset and choose how much analysis your app needs.

## Add the Package

Add MusaveraKit to your package dependencies:

```swift
.package(
    url: "https://github.com/rryam/MusaveraKit.git",
    from: "0.1.0"
)
```

Add `MusaveraKit` as a dependency of your app target, then import the package
with AVFoundation:

```swift
import AVFoundation
import MusaveraKit
```

## Analyze an Asset

Create an `AVAsset` for an audio resource your app can access:

```swift
let asset = AVURLAsset(url: audioURL)
let analysis = try await Musavera.analyze(asset: asset)
```

The default call asks Music Understanding for every supported dimension. The
returned ``MusaveraAnalysis`` retains the underlying
``MusicUnderstandingSession/SessionResult`` while exposing its most common
values directly.

## Select Analysis Types

Ask only for the work your interface needs:

```swift
let analysis = try await Musavera.analyze(
    asset: asset,
    options: [.rhythm, .key, .structure]
)
```

Use a focused helper for a single result:

```swift
let rhythm = try await Musavera.rhythm(for: asset)
```

Selecting fewer analysis types can reduce unnecessary computation. Passing an
empty option set throws ``MusaveraKitError/emptyAnalysisSet``.

## Handle Errors

MusaveraKit forwards errors thrown while creating or running a Music
Understanding session. Its focused helpers additionally throw
``MusaveraKitError/missingResult(_:)`` when the requested result is absent.

```swift
do {
    let key = try await Musavera.key(for: asset)
    print(key.primarySignature?.musaveraDescription as Any)
} catch {
    print("Analysis failed: \(error.localizedDescription)")
}
```

Music Understanding runs on device. Keep access to local or remote audio assets
valid for the duration of the asynchronous analysis.
