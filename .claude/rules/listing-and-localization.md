---
paths:
  - "fastlane/**/*"
  - "docs/*.html"
  - ".github/workflows/*"
  - "notes/asc-submission-checklist.md"
  - "scripts/write-localizations.py"
  - "scripts/asc-add-missing-localizations.*"
  - "scripts/asc-upload-metadata.*"
  - "scripts/asc-readiness.py"
---

# Electrician: store listing, site and localization

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

- **Store name is `Electrician Exam Practice 2026`.** The obvious
  `Electrician Exam Prep 2026` belongs to the incumbent the research file
  names as the SERP leader, and ASC rejects it with
  `DUPLICATE.DIFFERENT_ACCOUNT`. Keep the year suffix in whatever replaces
  it; that is the category's ranking lever. Name, subtitle and keywords are
  indexed as one bag, so a word in the name does not belong in the other two.

- Marketing site: `docs/` is served by Pages from `main` at
  `https://jackwallner.github.io/electrician/` (index, `privacy-policy`,
  `support`), and mirrored to `jackwallner.com/ios/electrician/` by
  `.github/workflows/sync-landing-page.yml`. That workflow needs the
  `PORTFOLIO_DEPLOY_KEY` secret on this repo before it can push the mirror.

- **Localized into all 50 ASC locales**, unlike the original US-only plan.
  Anything that touches the description touches 50 files, so change it with a
  script and verify against ASC rather than the repo.

- **Every localized description must carry a functional Terms of Use (EULA)
  link and a privacy link**, not just en-US. Each locale is its own product
  page and Apple checks each; 1.0 was rejected under 3.1.2 with the link in
  none of the 50. `scripts/asc-readiness.py` now names any locale that lacks
  it. en-US runs close to the 4000-character cap, so budget for those two
  lines before adding marketing copy.

- ASO: the category's ranking lever is the year in the app name
  (`Electrician Test Prep 2026` and friends all do it). Decide the store name
  from the research file, not from the fleet's `X Trainer` habit.
