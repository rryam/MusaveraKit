#!/bin/bash

set -euo pipefail

required_files=(
  "CODE_OF_CONDUCT.md"
  "CONTRIBUTING.md"
  "LICENSE"
  "Package.swift"
  "README.md"
  "SECURITY.md"
  "SUPPORT.md"
  "Sources/MusaveraKit/PrivacyInfo.xcprivacy"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required repository file: $file" >&2
    exit 1
  fi
done

swift package dump-package >/dev/null
swift package describe >/dev/null
plutil -lint Sources/MusaveraKit/PrivacyInfo.xcprivacy

ruby -e '
  require "yaml"
  Dir[".github/**/*.yml", ".github/**/*.yaml", ".spi.yml"].sort.each do |file|
    YAML.load_file(file)
  end
'

while IFS= read -r -d '' source; do
  xcrun swiftc -frontend -parse "$source"
done < <(find Sources Tests -name "*.swift" -print0)

echo "Repository validation passed."
