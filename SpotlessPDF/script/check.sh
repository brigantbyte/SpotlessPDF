#!/usr/bin/env bash
# Check the app's translations and save behavior using a previously built bundle.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/build/Build/Products/Debug/SpotlessPDF.app}"
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Build the app first, or pass its .app path as the first argument." >&2
    exit 1
fi
CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/spotlesspdf-checks.XXXXXX")"
trap 'rm -rf "$CHECK_DIR"' EXIT
FLAGS=(-disable-sandbox -module-cache-path "$CHECK_DIR/module-cache")
xcrun swiftc "${FLAGS[@]}" "$ROOT_DIR/SpotlessPDF/PDFOutputFile.swift" "$ROOT_DIR/Tests/PDFOutputFileChecks.swift" -o "$CHECK_DIR/names"
"$CHECK_DIR/names" "$APP_BUNDLE"
xcrun swiftc "${FLAGS[@]}" "$ROOT_DIR/SpotlessPDF/FolderDisplayName.swift" "$ROOT_DIR/Tests/FolderDisplayNameChecks.swift" -o "$CHECK_DIR/folders"
"$CHECK_DIR/folders" "$APP_BUNDLE"
xcrun swiftc "${FLAGS[@]}" -default-isolation MainActor "$ROOT_DIR/SpotlessPDF/Localization.swift" "$ROOT_DIR/SpotlessPDF/PDFCleaningService.swift" "$ROOT_DIR/Tests/NativeLanguageChecks.swift" -o "$CHECK_DIR/native"
"$CHECK_DIR/native"
xcrun swiftc "${FLAGS[@]}" -default-isolation MainActor "$ROOT_DIR/SpotlessPDF/DestinationFolderPicker.swift" "$ROOT_DIR/Tests/DestinationFolderPickerChecks.swift" -o "$CHECK_DIR/picker"
"$CHECK_DIR/picker"
mkdir -p "$CHECK_DIR/ServiceChecks.app/Contents/MacOS"
xcrun swiftc "${FLAGS[@]}" -default-isolation MainActor "$ROOT_DIR/SpotlessPDF/PDFCleaningService.swift" "$ROOT_DIR/Tests/PDFCleaningServiceChecks.swift" -o "$CHECK_DIR/ServiceChecks.app/Contents/MacOS/ServiceChecks"
"$CHECK_DIR/ServiceChecks.app/Contents/MacOS/ServiceChecks"
