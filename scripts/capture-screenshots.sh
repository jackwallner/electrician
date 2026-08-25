#!/usr/bin/env bash
# Capture the App Store screenshot set from the real app.
#
# Usage:
#   scripts/capture-screenshots.sh <simulator-udid> <output-dir> [prefix]
#
# The iPad set needs a 13-inch device (2064x2752); the pool has no iPad Pro, so
# scripts/with-ipad-sim.sh creates a throwaway one and hands the UDID over.
# Runs headless: it never opens Simulator.app.
set -euo pipefail

UDID="${1:?usage: capture-screenshots.sh <udid> <output-dir> [prefix]}"
OUT="${2:?usage: capture-screenshots.sh <udid> <output-dir> [prefix]}"
PREFIX="${3:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULT="$ROOT/build/screenshots.xcresult"
rm -rf "$RESULT"
mkdir -p "$ROOT/build"

cd "$ROOT"
# Export whatever the run captured even when the test reports a failure: a
# missing element on screen 4 should not throw away screens 1 to 3.
VERSION="$(awk '/MARKETING_VERSION/ {gsub(/[":]/, "", $2); print $2; exit}' project.yml)"

# TEST_RUNNER_-prefixed settings arrive in the UI test process as plain env
# vars, which is how the runner learns the marketing version it must mark as
# already seen to keep the What's New sheet off every screenshot.
xcodebuild test \
  -project Electrician.xcodeproj \
  -scheme Screenshots \
  -destination "id=$UDID" \
  -resultBundlePath "$RESULT" \
  -only-testing:ElectricianScreenshots/ScreenshotTests \
  TEST_RUNNER_SCREENSHOT_APP_VERSION="$VERSION" \
  || echo "xcodebuild reported failures; exporting what was captured" >&2

STAGE="$(mktemp -d)"
xcrun xcresulttool export attachments --path "$RESULT" --output-path "$STAGE"

mkdir -p "$OUT"
# The manifest maps Xcode's generated filenames back to the names the test gave
# each attachment; without it every shot lands as a UUID.
python3 - "$STAGE" "$OUT" "$PREFIX" <<'PY'
import json, pathlib, shutil, sys

stage, out, prefix = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
manifest = json.loads((stage / "manifest.json").read_text())

copied = 0
for entry in manifest:
    for att in entry.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or att.get("exportedFileName", "")
        src = stage / att["exportedFileName"]
        if not src.exists() or not name:
            continue
        # Xcode appends `_0_<uuid>` to attachment names. Strip it so the
        # required-set check and later ASC sync see the stable test name.
        stem = pathlib.Path(name).stem.split("_0_")[0]
        shutil.copyfile(src, out / f"{prefix}{stem}{src.suffix}")
        copied += 1
print(f"wrote {copied} screenshots to {out}")

# The test deliberately never fails hard on a missing element, because a slow
# XCTFail turns every navigation typo into a ten-minute diagnostic collection.
# That resilience is right for development and wrong for a release: it will
# happily export three shots and exit 0, and an App Store listing missing half
# its screenshots is not the kind of thing anyone catches before review.
REQUIRED = [
    "01_quick_session", "02_article_match", "03_ampacity_quiz",
    "04_worked_calc", "05_home", "06_basics_room",
]
captured = {
    path.stem[len(prefix):] if prefix and path.stem.startswith(prefix) else path.stem
    for path in out.glob("*.png")
}
missing = [name for name in REQUIRED if name not in captured]
if missing:
    print("MISSING required screenshots: " + ", ".join(missing), file=sys.stderr)
    print("See the 'problems' attachment in build/screenshots.xcresult.", file=sys.stderr)
    sys.exit(1)
PY
