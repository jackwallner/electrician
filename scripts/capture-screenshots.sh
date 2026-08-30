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

# Provenance, written beside the finals rather than left implicit. The shared
# renderer's audit refuses to call a set release-ready without a capture report
# whose hashes match the sources the manifest points at, which is exactly the
# check that would have caught the set shot two rebrands ago.
python3 - "$OUT" "$UDID" "$VERSION" <<'PY'
import hashlib, json, pathlib, subprocess, sys

out, udid, version = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
root = pathlib.Path(__file__).resolve().parent.parent if "__file__" in dir() else pathlib.Path.cwd()

# One named flow per required screen, so a frame can cite the run that made it.
FLOWS = {
    "01_quick_session": "quick_session",
    "02_article_match": "article_match",
    "03_ampacity_quiz": "ampacity_mistake_feedback",
    "04_worked_calc": "worked_calc_answered",
    "05_home": "home",
    "06_basics_room": "code_basics",
}

def sh(*args: str) -> str:
    return subprocess.run(args, capture_output=True, text=True).stdout.strip()

devices = json.loads(sh("xcrun", "simctl", "list", "devices", "-j"))["devices"]
device = {}
for runtime, entries in devices.items():
    for entry in entries:
        if entry["udid"] == udid:
            device = {"udid": udid, "name": entry["name"], "runtime": runtime,
                      "device_type": entry.get("deviceTypeIdentifier", "")}

records = []
for path in sorted(out.glob("*.png")):
    data = path.read_bytes()
    width = int.from_bytes(data[16:20], "big")
    height = int.from_bytes(data[20:24], "big")
    records.append({
        "path": str(path.resolve()),
        "flow": FLOWS.get(path.stem, path.stem),
        "sha256": hashlib.sha256(data).hexdigest(),
        "width": width,
        "height": height,
    })

report = {
    "status": "ok",
    "app": "electrician",
    "mode": "command",
    "proof_only": False,
    "lease_checked_in": True,
    "marketing_version": version,
    "build": sh("awk", "/CURRENT_PROJECT_VERSION/ {gsub(/[\":]/, \"\", $2); print $2; exit}", "project.yml"),
    "scheme": "Screenshots",
    "app_repo": {"path": str(pathlib.Path.cwd()), "git_commit": sh("git", "rev-parse", "HEAD")},
    "device": device,
    "flows": [{"id": flow} for flow in sorted(set(FLOWS.values()))],
    "screenshots": [record["path"] for record in records],
    "screenshot_records": records,
}
(out / "capture-report.json").write_text(json.dumps(report, indent=2) + "\n")
print(f"wrote {out}/capture-report.json")
PY
