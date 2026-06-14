# Changelog

All notable changes to MusaveraKit are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.2.0 - 2026-06-13

### Added

- Streaming PCM analysis through `MusaveraStreamingSession`, including
  realtime loudness results and final aggregate analysis.
- A Live Stream workspace in Musavera Lab with microphone capture, realtime
  loudness visualization, recording playback, completed musical analysis, and
  JSON export.
- A native Icon Composer app icon for Musavera Lab.

### Changed

- Reused the completed-analysis presentation across imported audio, Apple Music
  previews, and live recordings.
- Coordinated capture and playback as users move between the Analyze Music and
  Live Stream workspaces.

### Fixed

- Prevented stale microphone-permission responses from starting capture after
  leaving the Live Stream workspace.
- Made live-stream finalization and error presentation resilient to workspace
  changes.

## 0.1.0 - 2026-06-13

### Added

- Async APIs for complete and selected Music Understanding analysis.
- Focused helpers for rhythm, key, loudness, pace, structure, and instrument
  activity.
- An app-friendly aggregate result with common summary values.
- Timeline helpers for key, rhythm, structure, and instrument activity.
- Codable support for exporting complete native Music Understanding results.
- A macOS Musavera Lab example that combines Apple Music catalog search,
  artwork, preview analysis, full-song playback, synchronized visualizations,
  and JSON export.
- Swift Testing coverage for package-owned option and time-range behavior.
- DocC documentation, package validation, privacy metadata, and community
  contribution files.
