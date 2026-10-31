#!/usr/bin/env python3
"""Fail when the app names an SF Symbol that its minimum iOS cannot draw.

SF Symbol names resolve at run time, so the compiler never flags one that is
newer than the deployment target: on the older OS the Image is simply empty.
This reads the symbol-availability table that ships with macOS and compares
every symbol-shaped string literal in the app sources against the iOS version
in project.yml.

Run it on a Mac whose macOS is at least as new as the deployment target's
(macOS 14 or later for iOS 17).

    python3 scripts/check-sf-symbols.py
"""
import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AVAILABILITY = Path(
    "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist"
)
SOURCE_DIRS = ("Electrician", "Shared")
# Dotted lowercase literals that are keys or identifiers, not symbols.
NOT_SYMBOLS = (
    "candidate.", "settings.", "progress.", "practice.", "com.", "electrician.",
    "duo.", "codeminute.", "whatsnew.", "subscription.", "reviewprompt.", "conv.",
)
LITERAL = re.compile(r'"([a-z][a-z0-9]*(?:\.[a-z0-9]+)+)"')


def deployment_target() -> tuple[int, ...]:
    text = (ROOT / "project.yml").read_text(encoding="utf-8")
    match = re.search(r'deploymentTarget:\s*\n\s*iOS:\s*"?([0-9.]+)"?', text)
    if not match:
        sys.exit("check-sf-symbols: no iOS deploymentTarget in project.yml")
    return tuple(int(part) for part in match.group(1).split("."))


def version(text: str) -> tuple[int, ...]:
    return tuple(int(part) for part in text.split("."))


def main() -> int:
    if not AVAILABILITY.exists():
        sys.exit("check-sf-symbols: needs a Mac (CoreGlyphs symbol table not found)")
    table = plistlib.loads(AVAILABILITY.read_bytes())
    symbols, releases = table["symbols"], table["year_to_release"]
    target = deployment_target()

    problems = []
    for directory in SOURCE_DIRS:
        for path in sorted((ROOT / directory).rglob("*.swift")):
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                for name in LITERAL.findall(line):
                    if name.startswith(NOT_SYMBOLS):
                        continue
                    where = f"{path.relative_to(ROOT)}:{number}"
                    year = symbols.get(name)
                    if year is None:
                        problems.append(f"{where}: {name} is not in this Mac's symbol set (newer than macOS here, or not a symbol)")
                    elif version(releases[year]["iOS"]) > target:
                        problems.append(f"{where}: {name} needs iOS {releases[year]['iOS']}, target is {'.'.join(map(str, target))}")

    for problem in problems:
        print(problem)
    print(f"check-sf-symbols: {len(problems)} problem(s) against iOS {'.'.join(map(str, target))}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
