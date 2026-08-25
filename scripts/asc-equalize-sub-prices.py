#!/usr/bin/env python3
"""Fill per-territory subscription prices from the USA base price.

Setting only the USA price does NOT auto-populate the other territories, no
matter what asc-setup-release.py's log line claims. The subscription stays at
MISSING_METADATA, and a product in that state is never served to StoreKit, so
the paywall renders empty in sandbox and TestFlight. Apple exposes the
equivalent price point per territory as the USA point's `equalizations`.

Non-consumables are unaffected: their `inAppPurchasePriceSchedules` really does
equalize from `baseTerritory`. This is a subscriptions-only gap.

Idempotent: territories that already carry a price row are skipped.

    source ~/.baseball_credentials && python3 scripts/asc-equalize-sub-prices.py
"""

from __future__ import annotations

import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

BUNDLE = "com.jackwallner.electrician"
USA_PRICES = {
    "com.jackwallner.electrician.monthly": "9.99",
    "com.jackwallner.electrician.yearly": "39.99",
}
ONLY = set(sys.argv[1:])


def priced_territories(c: asc_lib.ASCClient, sub_id: str) -> set[str]:
    """Territory ids that already have a price row on this subscription."""
    priced: set[str] = set()
    path = f"/subscriptions/{sub_id}/prices?include=territory&limit=200"
    while path:
        page = c.get(path)
        for included in page.get("included") or []:
            if included["type"] == "territories":
                priced.add(included["id"])
        nxt = (page.get("links") or {}).get("next")
        path = nxt.replace(asc_lib.API, "") if nxt else None
    return priced


def main() -> None:
    c = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(c, BUNDLE)

    for group in c.get(f"/apps/{app['id']}/subscriptionGroups")["data"]:
        for sub in c.get(f"/subscriptionGroups/{group['id']}/subscriptions")["data"]:
            product_id = sub["attributes"]["productId"]
            target = USA_PRICES.get(product_id)
            if not target or (ONLY and product_id not in ONLY):
                continue

            priced = priced_territories(c, sub["id"])
            print(f"{product_id}: {len(priced)} territories already priced")

            points = asc_lib.list_all(
                c, f"/subscriptions/{sub['id']}/pricePoints?filter[territory]=USA&limit=200"
            )
            usa_point = next(
                p for p in points if p["attributes"]["customerPrice"] == target
            )
            equalizations = asc_lib.list_all(
                c,
                f"/subscriptionPricePoints/{urllib.parse.quote(usa_point['id'], safe='')}"
                f"/equalizations?include=territory&limit=200",
            )

            created = failed = 0
            for point in equalizations:
                territory = (
                    (point.get("relationships") or {}).get("territory", {}).get("data") or {}
                ).get("id")
                if not territory or territory in priced:
                    continue
                try:
                    # No attributes and no territory relationship: adding either
                    # 409s on the price point for a pre-launch subscription.
                    c.post(
                        "/subscriptionPrices",
                        {
                            "data": {
                                "type": "subscriptionPrices",
                                "relationships": {
                                    "subscription": {
                                        "data": {"type": "subscriptions", "id": sub["id"]}
                                    },
                                    "subscriptionPricePoint": {
                                        "data": {
                                            "type": "subscriptionPricePoints",
                                            "id": point["id"],
                                        }
                                    },
                                },
                            }
                        },
                    )
                    created += 1
                except RuntimeError as error:
                    failed += 1
                    print(f"  {territory}: {str(error)[:120]}", file=sys.stderr)

            print(f"{product_id}: posted {created} territory prices ({failed} failed)")

    print("done")


if __name__ == "__main__":
    main()
