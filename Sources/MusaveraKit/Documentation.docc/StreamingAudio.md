# Analyze Streaming Audio

Feed live PCM buffers to Music Understanding and update loudness meters while
audio is still arriving.

## Create a Streaming Session

Create a nonthrowing asynchronous sequence of
`AVReadOnlyAudioPCMBuffer` values:

```swift
import AVFoundation
import MusaveraKit

let (buffers, continuation) =
    AsyncStream<AVReadOnlyAudioPCMBuffer>.makeStream()

let session = MusaveraStreamingSession(audioProvider: buffers)
```

Xcode 27 adds a sendable audio tap that produces the required read-only
buffers directly:

```swift
let engine = AVAudioEngine()
let input = engine.inputNode
let format = input.outputFormat(forBus: 0)

try input.installAudioTap(
    onBus: 0,
    bufferSize: 4_800,
    format: format
) { buffer, _ in
    continuation.yield(buffer)
}
```

## Observe Realtime Loudness

Iterate ``MusaveraStreamingSession/loudnessResults`` while analysis runs:

```swift
let loudnessTask = Task {
    for try await loudness in session.loudnessResults {
        updateMeter(with: loudness)
    }
}

let analysisTask = Task {
    try await session.analyze()
}

engine.prepare()
try engine.start()
```

Finish the provider when capture stops, then await the final analysis:

```swift
engine.stop()
input.removeTap(onBus: 0)
continuation.finish()

let analysis = try await analysisTask.value
loudnessTask.cancel()
```

Realtime delivery is currently available for loudness. Key, rhythm, pace,
structure, and instrument activity are returned in the complete
``MusaveraAnalysis`` after the audio sequence ends.
