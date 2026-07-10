# Releasing MusaveraKit

MusaveraKit follows semantic versioning. Before `1.0.0`, a minor version may
contain source-breaking changes needed to follow Apple's beta SDK.

## Prepare

1. Start from a clean, current `main` branch.
2. Choose the version and review all changes since the previous tag.
3. Move completed entries from `Unreleased` in `CHANGELOG.md` into a dated
   version section.
4. Confirm public API additions have DocC comments and tests.
5. Verify that no credentials, signing assets, or copyrighted test media are
   present.

## Validate

Select Xcode 27, then run:

```bash
Scripts/validate-repository.sh
swift test
xcodebuild \
  -scheme MusaveraKit \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/xcode \
  build
swift package generate-documentation \
  --target MusaveraKit \
  Sources/MusaveraKit/Documentation.docc
git diff --check
```

Record the exact Xcode and operating-system builds used for the release.

## Publish

Commit the changelog update separately, then create an annotated tag:

```bash
git tag -a VERSION -m "MusaveraKit VERSION"
git push origin main
git push origin VERSION
```

Use a `VERSION` in the form `0.1.0`, without a leading `v`, so Swift Package
Manager can resolve it directly.

Create the GitHub release from the tagged changelog notes:

```bash
gh release create VERSION \
  --verify-tag \
  --title "MusaveraKit VERSION" \
  --notes-file RELEASE_NOTES.md
```

After publishing, verify that Swift Package Manager resolves the tag and that
the GitHub release, license, and generated documentation are visible.
