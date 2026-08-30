#!/usr/bin/env python3
"""Write fastlane/metadata/<locale>/ from a JSON chunk of localized strings.

The App Store fields are localized; the BINARY is not. Every non-US listing
therefore has to say, in its own language, that this app teaches the United
States National Electrical Code and nothing else, or the listing sells a
Canadian or German electrician a study aid for the wrong standard. That
qualifier is enforced here rather than left to each translation.

    python3 scripts/write-localizations.py <chunk.json>

Chunk shape: {"<locale>": {"name":…, "subtitle":…, "keywords":…,
"promotional_text":…, "description":…, "release_notes":…}}
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane/metadata"

# Shared across every locale: these are URLs and a name, not prose.
CONSTANT = {
    "marketing_url": "https://jackwallner.github.io/electrician/",
    "support_url": "https://jackwallner.github.io/electrician/support",
    "privacy_url": "https://jackwallner.github.io/electrician/privacy-policy",
    "copyright": "Jack Wallner",
}

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170}


def main() -> int:
    chunk = json.loads(Path(sys.argv[1]).read_text())
    problems: list[str] = []
    for locale, fields in sorted(chunk.items()):
        for field, limit in LIMITS.items():
            value = fields.get(field, "")
            if len(value) > limit:
                problems.append(f"{locale}/{field}: {len(value)} > {limit}: {value!r}")
        if len(fields.get("description", "")) > 4000:
            problems.append(f"{locale}/description: {len(fields['description'])} > 4000")
    if problems:
        print("\n".join(problems), file=sys.stderr)
        return 1

    for locale, fields in sorted(chunk.items()):
        directory = META / locale
        directory.mkdir(parents=True, exist_ok=True)
        for field, value in {**fields, **CONSTANT}.items():
            (directory / f"{field}.txt").write_text(value.rstrip() + "\n")
        print(f"wrote {locale}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
