---
paths:
  - "scripts/asc-*.py"
  - "scripts/rc-*.py"
  - "scripts/capture-paywall.sh"
  - "Electrician/Electrician.storekit"
  - "Shared/Services/SubscriptionService.swift"
---

# Electrician: IAP setup and RevenueCat

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

- **IAP setup is three scripts in order**, and skipping one leaves every product
  at `MISSING_METADATA`, where StoreKit never serves it and the paywall is dead
  on device: `asc-setup-release.py` (products, USA price, trials, categories),
  `asc-equalize-sub-prices.py` (the other 174 territories, because subscription
  prices do NOT equalize from the USA row the way a non-consumable schedule
  does), then `asc-finish-products.py --screenshot` (App Review screenshot).
  Subscriptions in one group also need distinct `groupLevel`s. Capture the
  screenshot with `scripts/capture-paywall.sh <udid> <dir>`.

- **Re-run `scripts/rc-setup.py` after touching products or offerings**, then
  probe with the iOS platform header. The project shipped with the fleet's
  recurring empty-offering bug (Test Store products only, so iOS filtered every
  package out and the paywall was dead on device). Fixed 2026-08-24. A
  simulator can never catch this because it never configures RevenueCat (the
  Debug paywall reads `Electrician.storekit` instead, which is excluded from
  Release so the price catalog never ships in the binary):

  ```sh
  curl -s -H "Authorization: Bearer appl_JNXhRRCBfqpJqOpxFnylwNcqvby" \
       -H "X-Platform: ios" \
       https://api.revenuecat.com/v1/subscribers/probe-1/offerings
  ```
