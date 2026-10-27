#!/usr/bin/env python3
"""Compile the iOS content and generate Android content and parity fixtures."""

import argparse
import hashlib
import json
from pathlib import Path
import re
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
        "CandidateMistake.kt": repo / "android/app/src/main/java/com/jackwallner/electrician/model/CandidateMistake.kt",
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
        patterns = []
        for source in sorted((repo / "Shared/Content").glob("CalcGenerator*.swift")):
            patterns.extend(re.findall(r'static let\s+(\w+)\s*=\s*MistakePattern\(\s*id:\s*"([^"]+)"', source.read_text()))
        exported = json.loads((work / "electrician-content.json").read_text())["mistakePatterns"]
        if {value for _, value in patterns} != {value["id"] for value in exported}:
            raise SystemExit("Swift mistake aliases do not match the compiled registry")
        aliases = "\n".join(f'    val {name}: MistakePattern get() = required("{identity}")' for name, identity in sorted(patterns))
        (work / "CandidateMistake.kt").write_text('''package com.jackwallner.electrician.model

import com.jackwallner.electrician.content.ElectricianContent
import com.jackwallner.electrician.content.objects

// Generated from the Swift catalog by scripts/sync-android-content.py.
object CandidateMistake {
    val all: List<MistakePattern> by lazy {
        ElectricianContent.raw.getJSONArray("mistakePatterns").objects().map {
            MistakePattern(it.getString("id"), it.getString("skill"), it.getString("summary"))
        }
    }
    private val byID: Map<String, MistakePattern> by lazy { all.associateBy { it.id } }
    fun pattern(id: String): MistakePattern? = byID[id]
    private fun required(id: String): MistakePattern = checkNotNull(pattern(id))
''' + aliases + '\n}\n')
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
