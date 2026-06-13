# Working with Analysis Results

Connect Music Understanding results to labels, timelines, and
playback-synchronized interfaces.

## Use the Aggregate Result

``MusaveraAnalysis`` wraps the framework session result and exposes each
optional result:

```swift
let analysis = try await Musavera.analyze(asset: asset)

let rhythm = analysis.rhythm
let key = analysis.key
let loudness = analysis.loudness
let pace = analysis.pace
let structure = analysis.structure
let instruments = analysis.instrumentActivity
```

Use `analysis.result` when you need the original
``MusicUnderstandingSession/SessionResult``.

## Show Summary Values

MusaveraKit includes counts and values commonly shown in an overview:

```swift
analysis.beatsPerMinute
analysis.beatCount
analysis.barCount
analysis.sectionCount
analysis.phraseCount
analysis.segmentCount
```

For a simple key label, use the first detected signature:

```swift
let label = analysis.key?.primarySignature?.musaveraDescription
```

## Follow Playback Time

Pass the current `CMTime` into timeline helpers:

```swift
let signature = analysis.keySignature(at: playbackTime)
let beat = analysis.rhythm?.nearestBeat(to: playbackTime)
let bar = analysis.rhythm?.nearestBar(to: playbackTime)

let section = analysis.structure?.section(containing: playbackTime)
let phrase = analysis.structure?.phrase(containing: playbackTime)
let segment = analysis.structure?.segment(containing: playbackTime)
```

Range containment includes the start time and excludes the end time, matching
`CMTimeRange` behavior.

## Inspect Instrument Activity

Use convenience ranges for the four instrument categories:

```swift
let vocals = analysis.instrumentActivity?.vocalRanges
let drums = analysis.instrumentActivity?.drumRanges
let bass = analysis.instrumentActivity?.bassRanges
let other = analysis.instrumentActivity?.otherRanges
```

For an activity curve instead of ranges, request the timed values:

```swift
let vocalActivity = analysis.instrumentActivity?.activity(for: .vocal)
```

Keep the native result types when building a richer visualization; the package
adds conveniences without replacing Music Understanding's data model.
