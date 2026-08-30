# App Store Connect submission checklist

Everything on this list is automated except App Privacy. That one has no
public App Store Connect API: the `appDataUsages` resources live on the
internal `iris` host, which rejects an App Store Connect API key, and
fastlane's `upload_app_privacy_details_to_app_store` calls
`Spaceship::ConnectAPI.login` with an Apple ID and password. So it is a web-UI
job, and it is the only thing standing between this app and review.

## The one manual step: App Privacy

<https://appstoreconnect.apple.com/apps/6804828725/distribution/privacy> ->
**Get Started**.

**Do you collect data from this app?** -> **Yes**. The app itself stores
everything on device and has no analytics, no crash reporter and no server of
its own, but RevenueCat receives purchase data, and Apple counts a third-party
SDK's collection as yours.

Select exactly two data types:

| Data type | Why it is collected | Linked to identity | Used for tracking |
|---|---|---|---|
| Purchases -> Purchase History | App Functionality | No | No |
| Identifiers -> Device ID | App Functionality | No | No |

Purchase History is what RevenueCat needs to know whether `electrician_pro` is
entitled. Device ID is the IDFV that the SDK sends by default: the app never
calls `logIn`, so the customer is an anonymous RevenueCat id and there is no
account to link either value to.

Nothing else applies. No contact info, no user content, no identifiers beyond
the IDFV, no diagnostics, no location, and **no tracking**: nothing is shared
with a data broker or joined to third-party data for advertising, and the app
has no `NSUserTrackingUsageDescription` because it never asks.

Then **Publish**. "Saved" is not enough; the submission checks for PUBLISHED
answers and fails with `STATE_ERROR.APP_DATA_USAGES_REQUIRED` until you press
it.

## Then submit

```sh
set -a; source ~/.baseball_credentials; set +a
python3 scripts/asc-readiness.py          # read-only report
python3 scripts/asc-submit-for-review.py  # --dry-run to prepare without sending
```

The three products ride along automatically. Apple refuses to review a first
non-consumable on its own (`FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION`),
and `reviewSubmissionItems` has no in-app-purchase relationship to add one with,
so the version item carries `lifetime`, `monthly` and `yearly` with it. The
submit script prints them before it sends, which is the moment to notice a
product that quietly fell out of `READY_TO_SUBMIT`.

## After it goes Ready for Sale

Flip `AppStoreLinks.isListingLive` to `true` and ship a build. Until then there
is no share URL, no Rate button and no review funnel, because every
`apps.apple.com/app/id...` URL built from a draft record 404s.
