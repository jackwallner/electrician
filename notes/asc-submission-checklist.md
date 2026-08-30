# App Store Connect submission checklist

Everything on this list is automated except App Privacy, and that one is the
only thing standing between this app and review. It has no App Store Connect
API: the `appDataUsages` resources live on the internal `iris` host, which
rejects an API key, and fastlane's action calls `Spaceship::ConnectAPI.login`
with an Apple ID and password. So it needs a human login, one way or another.

## The one manual step: App Privacy

The answers are already written, in `fastlane/app_privacy_details.json`. Run:

```sh
./scripts/fastlane-bin.sh run upload_app_privacy_details_to_app_store \
  username:jackwallner@gmail.com \
  app_identifier:com.jackwallner.electrician \
  json_path:fastlane/app_privacy_details.json
```

It prompts for the Apple ID password and a 2FA code, then creates and
**publishes** the answers. "Saved but not published" is the failure mode to
watch for: the submission checks for PUBLISHED answers and fails with
`STATE_ERROR.APP_DATA_USAGES_REQUIRED` until they are.

The equivalent by hand is
<https://appstoreconnect.apple.com/apps/6804828725/distribution/privacy> ->
Get Started -> **Yes, we collect data** -> exactly two types -> Publish:

| Data type | Why | Linked to identity | Used for tracking |
|---|---|---|---|
| Purchases -> Purchase History | App Functionality | No | No |
| Identifiers -> Device ID | App Functionality | No | No |

### Why those two, and nothing else

The app stores everything on device and has no analytics, no crash reporter and
no server of its own. Issue reports and feedback leave as a `mailto:` draft in
the reader's own mail app, which is not collection. But RevenueCat is a
third-party SDK, and Apple counts what it collects as ours: Purchase History is
what it needs to decide whether `electrician_pro` is entitled, and Device ID is
the IDFV its SDK sends by default.

Neither is linked to an identity, because the app never calls `Purchases.logIn`
and the customer is an anonymous RevenueCat id with no account behind it.
Neither is tracking: nothing is shared with a data broker or joined to
third-party data for advertising, and there is no
`NSUserTrackingUsageDescription` in `Info.plist` because the app never asks.

## Then submit

```sh
set -a; source ~/.baseball_credentials; set +a
python3 scripts/asc-readiness.py          # read-only report
python3 scripts/asc-submit-for-review.py  # --dry-run to prepare without sending
```

## The products go along with the version

There is no product item to add, and that is Apple's rule rather than a gap in
the scripts: "The first Non-Consumable In-App Purchase for this app must be
submitted for review at the same time that you submit an app version."
`reviewSubmissionItems` has no `inAppPurchaseV2` or `subscription` relationship
to add one with, and `POST /inAppPurchaseSubmissions` refuses a first product
outright. The version item carries all three.

What decides whether one actually goes along is whether it is COMPLETE, because
an incomplete product is dropped silently. `asc-readiness.py` checks the four
things that drop one — a localization, a price, an App Review screenshot and an
availability — and prints `complete` or the missing pieces per product. Read
that line before submitting. As of build 11 all three are complete, at the
9.99 / 39.99 / 89.99 ladder that `Electrician.storekit` and the
`SubscriptionService` fallback also quote, with a 7-day trial on both
subscriptions across 175 territories and distinct group levels (yearly 1,
monthly 2).

## After it goes Ready for Sale

Flip `AppStoreLinks.isListingLive` to `true` and ship a build. Until then there
is no share URL, no Rate button and no review funnel, because every
`apps.apple.com/app/id...` URL built from a draft record 404s.
