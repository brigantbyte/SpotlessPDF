#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode-beta.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
fi
case "$MODE" in
    run|--build|--verify|--debug|--logs|--telemetry) ;;
    *) echo "Usage: $0 [--build|--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;;
esac
if [[ "$MODE" != --build ]]; then pkill -x SpotlessPDF >/dev/null 2>&1 || true; fi
xcodebuild -project "$ROOT_DIR/SpotlessPDF.xcodeproj" -scheme SpotlessPDF -configuration Debug -derivedDataPath "$ROOT_DIR/build" CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
APP_BUNDLE="$ROOT_DIR/build/Build/Products/Debug/SpotlessPDF.app"
case "$MODE" in
    --build) exit 0 ;;
    --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/SpotlessPDF" ;;
    *)
        /usr/bin/open -n "$APP_BUNDLE"
        case "$MODE" in
            --verify) sleep 1; pgrep -x SpotlessPDF >/dev/null ;;
            --logs) /usr/bin/log stream --info --style compact --predicate 'process == "SpotlessPDF"' ;;
            --telemetry) /usr/bin/log stream --info --style compact --predicate 'subsystem == "brigantbyte.SpotlessPDF"' ;;
        esac ;;
esac
