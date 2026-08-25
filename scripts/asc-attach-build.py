#!/usr/bin/env python3
"""Attach the requested valid uploaded build to the editable ASC version."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import asc_lib as L

BUNDLE_ID = "com.jackwallner.electrician"


def build_number_from_project() -> str | None:
    project = (L.ROOT / "project.yml").read_text(encoding="utf-8")
    match = re.search(r'CURRENT_PROJECT_VERSION:\s*"([^"]+)"', project)
    return match.group(1) if match else None


def numeric_build_number(value: str) -> int:
    try:
        return int(value)
    except ValueError:
        return -1


def main() -> int:
    client = L.ASCClient(L.bearer_token(*L.load_credentials()))
    app = L.find_app(client, BUNDLE_ID)
    version = L.find_editable_version(client, app["id"])
    if not version:
        print("error: no editable app store version", file=sys.stderr)
        return 1

    version_id = version["id"]
    version_string = version["attributes"]["versionString"]
    requested = os.environ.get("ASC_BUILD_NUMBER") or build_number_from_project()
    current = client.get(f"/appStoreVersions/{version_id}/build").get("data")
    if current:
        current_resource = current
        if "attributes" not in current_resource:
            current_resource = client.get(f"/builds/{current['id']}").get("data") or current
        current_number = current_resource.get("attributes", {}).get("version")
        if not requested or current_number == requested:
            print(f"build already attached: {current['id']}")
            return 0
        print(f"replacing attached build {current_number or current['id']} with build {requested}")

    builds = L.list_all(client, f"/builds?filter[app]={app['id']}&limit=200&sort=-version")
    candidates: list[dict] = []
    for build in builds:
        attrs = build["attributes"]
        if attrs.get("processingState") != "VALID" or attrs.get("expired"):
            continue
        if requested and attrs.get("version") != requested:
            continue
        prerelease = client.get(f"/builds/{build['id']}/preReleaseVersion").get("data")
        if not prerelease or prerelease["attributes"].get("version") != version_string:
            continue
        candidates.append(build)

    if not candidates:
        print(
            f"error: no valid build for version {version_string}"
            + (f" and build {requested}" if requested else ""),
            file=sys.stderr,
        )
        return 1

    build = max(candidates, key=lambda item: numeric_build_number(item["attributes"].get("version", "")))
    client.patch(
        f"/appStoreVersions/{version_id}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build["id"]}}
                },
            }
        },
    )
    print(f"attached build {build['attributes']['version']} to version {version_string}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
