# Contributing to MusaveraKit

Thanks for helping improve MusaveraKit. Contributions should keep the package
small, predictable, and closely aligned with Apple's MusicUnderstanding types.

By participating, you agree to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Before You Start

- Search existing issues and pull requests.
- Open an issue before a large API or architectural change.
- Use Feedback Assistant for bugs that reproduce in MusicUnderstanding without
  MusaveraKit.
- Never include Apple Music credentials, signing assets, or private media in a
  report or test fixture.

## Development Requirements

- macOS 27 beta or later
- Xcode 27 beta or later
- Swift 6.4 or later

MusicUnderstanding is part of the Xcode 27 beta SDK and macOS 27 runtime. An
older Xcode can parse the package manifest, but it cannot compile or run the
package.

## Setup

```bash
git clone https://github.com/rryam/MusaveraKit.git
cd MusaveraKit
```

If Xcode 27 beta is not the active developer directory:

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
```

Use the actual Xcode beta path installed on your Mac.

## Build and Test

Run the package tests:

```bash
swift test
```

Build a platform target with Xcode:

```bash
xcodebuild \
  -scheme MusaveraKit \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/xcode \
  build
```

Before opening a pull request, also run:

```bash
git diff --check
swift package dump-package >/dev/null
plutil -lint Sources/MusaveraKit/PrivacyInfo.xcprivacy
```

## Documentation

Public APIs require DocC comments. Update the DocC catalog when behavior,
requirements, or recommended usage changes.

Generate the documentation locally with:

```bash
swift package generate-documentation --target MusaveraKit
```

Preview it with:

```bash
swift package --disable-sandbox preview-documentation --target MusaveraKit
```

## Code Style

- Use Swift 6 concurrency and preserve strict-concurrency correctness.
- Prefer focused extensions and small value types over broad abstractions.
- Keep public names consistent with MusicUnderstanding terminology.
- Avoid third-party runtime dependencies.
- Add tests for new behavior and bug fixes.
- Keep unrelated formatting or refactors out of focused changes.

## Pull Requests

Pull requests should include:

- the problem or use case
- the API and behavior that changed
- tests or concrete runtime verification
- documentation updates for user-facing changes
- the Xcode and operating-system builds used for validation

Small, focused commits are appreciated because this package tracks a rapidly
evolving beta SDK.
