#!/usr/bin/env python3
"""Compile the iOS content and generate Android content and parity fixtures."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    sources = sorted((repo / "Shared/Models").glob("*.swift")) + sorted((repo / "Shared/Content").glob("*.swift"))
    sources += [repo / "Electrician/Utilities/ChoiceShuffle.swift", repo / "scripts/android-export/main.swift"]
    targets = {
        "electrician-content.json": repo / "android/app/src/main/resources/electrician-content.json",
        "electrician-parity.json": repo / "android/app/src/test/resources/electrician-parity.json",
        "swift-content-manifest.json": repo / "android/app/src/main/resources/swift-content-manifest.json",
    }
    with tempfile.TemporaryDirectory(prefix="electrician-export-") as temporary:
        work = Path(temporary)
        binary = work / "export"
        candidate_source = repo / "Shared/Services/CandidateProfile.swift"
        candidate_marker = "\n@MainActor\nfinal class CandidateProfile:"
        candidate_text = candidate_source.read_text()
        if candidate_text.count(candidate_marker) != 1:
            raise SystemExit("Cannot isolate the original pure candidate enums")
        candidate_enums = work / "CandidateEnums.swift"
        candidate_enums.write_text(candidate_text.split(candidate_marker)[0])
        print("Compiling original Swift models, content and generators", flush=True)
        subprocess.run(["swiftc", "-whole-module-optimization", *(str(path) for path in sources), str(candidate_enums), "-o", str(binary)], check=True)
        subprocess.run([str(binary), str(work / "electrician-content.json"), str(work / "electrician-parity.json")], check=True)
        hashes = {str(path.relative_to(repo)): hashlib.sha256(path.read_bytes()).hexdigest() for path in [*sources, candidate_source]}
        (work / "swift-content-manifest.json").write_text(json.dumps({"schema": 1, "sources": hashes}, indent=2, sort_keys=True) + "\n")
        for name, target in targets.items():
            generated = (work / name).read_bytes()
            if args.check:
                if not target.exists() or target.read_bytes() != generated:
                    raise SystemExit(f"Outdated export: {target.relative_to(repo)}")
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(generated)
        print("Android exports match Swift" if args.check else "Android exports updated")


if __name__ == "__main__":
    main()
