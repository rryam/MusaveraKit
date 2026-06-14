# Musavera Lab

Musavera Lab composes two Apple frameworks without coupling their wrapper libraries:

1. `MusicKit` searches Apple Music and exposes a song's downloadable preview URL.
2. The app caches that DRM-free preview locally.
3. `MusaveraKit` analyzes the local asset with `MusicUnderstanding`.
4. `AVPlayer`, SwiftUI, and Swift Charts keep playback and analysis visuals in sync.
5. `ApplicationMusicPlayer` remains available as a separate full-song playback path.
6. A separate Live Stream workspace sends microphone PCM buffers to
   `MusaveraStreamingSession`, updates loudness while listening, and completes
   the full musical analysis after capture stops.

MusadoraKit is intentionally not a dependency. MusadoraKit and MusaveraKit remain focused siblings, while this app demonstrates how a product can compose their underlying Apple frameworks.

## Signal Chain Checklist

### Foundation

- [x] Keep the example inside the MusaveraKit repository.
- [x] Target macOS 27 so the app can run locally against MusicUnderstanding.
- [x] Reference the local MusaveraKit package product.
- [x] Use a dedicated bundle identifier: `com.rudrankriyam.musaveralab`.
- [x] Enable MusicKit for the App ID in Certificates, Identifiers & Profiles.

### Apple Music

- [x] Request MusicKit authorization with a clear usage description.
- [x] Search catalog songs with `MusicCatalogSearchRequest`.
- [x] Show artwork, title, artist, and preview availability.
- [x] Read `Song.previewAssets` directly from first-party MusicKit.
- [x] Offer full-song playback through `ApplicationMusicPlayer`.
- [x] Verify catalog search with a signed build and a real Apple Music account.
- [ ] Verify graceful behavior for a song with no preview.

### Audio Pipeline

- [x] Download the 30-second preview with `URLSession`.
- [x] Cache previews outside the source tree.
- [x] Copy security-scoped local files into the same cache.
- [x] Reject protected assets before analysis.
- [x] Build `AVURLAsset` with precise timing enabled.
- [x] Load the same asset into preview playback and MusaveraKit analysis.
- [x] Capture microphone input with the sendable macOS 27 audio tap.
- [x] Feed immutable PCM buffers into an asynchronous streaming provider.
- [x] Stop preview and full-song playback before live microphone analysis.
- [ ] Exercise a preview with redirects and a non-`m4a` extension.

### Understanding

- [x] Analyze key, rhythm, structure, pace, instrument activity, and loudness.
- [x] Use MusaveraKit's key and instrument convenience helpers.
- [x] Keep analysis work off the UI while exposing a simple app state machine.
- [x] Surface loudness results while microphone audio is still arriving.
- [x] Finish key, rhythm, structure, pace, instruments, and final loudness when
  the live stream closes.
- [ ] Add cancellation when a user chooses a different track mid-analysis.
- [x] Export the complete native MusicUnderstanding result as formatted JSON.

### Visuals

- [x] Show a synchronized playhead over time-based results.
- [x] Render structure sections, segments, and phrases.
- [x] Render pace, instrument ranges, activity curves, and loudness.
- [x] Make the timeline seekable.
- [x] Support local audio as a generic fallback.
- [x] Separate Analyze Music and Live Stream into native sidebar workspaces.
- [x] Show a rolling 30-second realtime loudness chart and input diagnostics.
- [x] Export completed live-stream analysis as formatted JSON.
- [x] Adapt activity charts from one to four columns as the window grows.
- [ ] Add a compact mode for smaller windows.
- [ ] Add reduced-motion tuning and VoiceOver summaries for every chart.

### Ship It

- [x] Build the app with Xcode 27.
- [x] Run the signed macOS app.
- [x] Search Apple Music and analyze a real preview end to end.
- [x] Visually inspect the idle, loading, and results states.
- [ ] Keep the package's existing tests green.

## Generate the Project

The checked-in Xcode project is generated from `project.yml`:

```bash
cd Examples/MusaveraLab
xcodegen generate
```

Then open `MusaveraLab.xcodeproj` with Xcode 27.

MusicKit is enabled as an App Service for the bundle identifier. It does not
add a MusicKit key to the app's code-signing entitlements.

The Live Stream workspace requires the App Sandbox audio-input entitlement and
microphone usage description. macOS asks for permission the first time capture
starts.

## Realtime Boundary

Music Understanding accepts an asynchronous stream of read-only PCM buffers.
Its loudness sequence can update a meter while those buffers arrive. The
session's aggregate result, including key, rhythm, structure, pace, and
instrument activity, completes after the provider finishes.

Musavera Lab uses the microphone for that live PCM path. MusicKit's
`ApplicationMusicPlayer` does not expose the decoded PCM of a full Apple Music
song, so the app does not claim to analyze protected full-song playback.

## Verified Track

The signed app was tested with Bruno Mars' "Grenade" from the Apple Music
catalog. Its artwork and 30-second preview loaded successfully, playback stayed
synchronized with the timelines, and MusicUnderstanding reported F major at
110 BPM for that preview excerpt. The result can be exported through the native
macOS save panel as formatted JSON.

## Apple Sample Attribution

The synchronized playback and visualization approach is adapted from Apple's
WWDC26 Music Understanding Lab sample. Apple's license is included in
`APPLE_SAMPLE_LICENSE.txt`.
