# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Status

This repository is a **standalone git repo** (`main` branch) initialized 2026-05-13. It currently contains specs and scaffolding only — no Swift or Python source code yet. The implementation is planned as two separate repos in the future: `agriprice-ios` and `agriprice-api`.

Build/test/lint commands: **none yet** — there is no Swift toolchain, no `package.json`, no `requirements.txt`, no Xcode project. Do not invent commands; if a future spec adds source code, this section needs updating.

## Spec-Driven Workflow (GitHub Spec Kit 0.7.4)

This repo uses **GitHub Spec Kit** for spec-driven development. Every new feature flows through:

1. `/speckit-specify` — create `specs/NNN-name/spec.md` from `.specify/templates/spec-template.md`
2. `/speckit-clarify` — surface `[NEEDS CLARIFICATION: ...]` markers (optional but recommended)
3. `/speckit-plan` — produce `specs/NNN-name/plan.md`
4. `/speckit-tasks` — produce `specs/NNN-name/tasks.md`
5. `/speckit-implement` — execute tasks

The feature-creation script auto-creates a `NNN-short-name` git branch and `specs/NNN-name/spec.md`:

```bash
powershell -NoProfile -ExecutionPolicy Bypass \
  -File .specify/scripts/powershell/create-new-feature.ps1 \
  -Json -ShortName "<slug>" "<description>"
```

Note: the scripts in `.specify/scripts/` are **PowerShell only** (no bash equivalents). On Windows, call via `powershell.exe`, not `pwsh` (pwsh-7 isn't installed on this machine).

### Source of truth precedence

When specs disagree, follow this order:

1. **`.specify/memory/constitution.md`** — non-negotiable principles. Conflicts here must be resolved before the feature can proceed.
2. **`specs/NNN-*/spec.md`** — the per-feature contract.
3. **`agriprice_development_spec.md`** — legacy reference doc. Still canonical for SwiftData model shapes (§7), API request/response shapes (§9–§13), error code strings (§17), and user-visible error message strings (§18).
4. **`agriprice_proposal.md`** — high-level motivation only; never used to resolve a concrete decision.

The legacy dev spec is **not deprecated** — it's still the source for shapes and strings — but it does not replace per-feature Spec Kit specs.

## Existing Features

| # | Branch | Spec |
|---|---|---|
| 001 | `001-market-price-query` | Query market prices across all markets by product code + date range (MarketView, TrendView, `/api/v1/market-prices`) |
| 002 | `002-vendor-transactions` | Vendor login + today's transactions (VendorView, `/api/v1/vendor/transactions`) |
| 003 | `003-ios-shell` | iOS app shell: 4-tab navigation, Home screen, SwiftData container |

Each lives on its own branch with `specs/NNN-*/spec.md` committed. None have `plan.md` or `tasks.md` yet.

## Constitution Highlights (Non-Negotiable)

Read `.specify/memory/constitution.md` in full before any non-trivial change. The principles that have killed past designs:

- **On-Device First**: no Cloud SQL, no Firestore, no server-side user data. SwiftData on iPhone is the only persistence.
- **Stateless Proxy**: FastAPI on Cloud Run is a pure adapter. No DB, no cache, no background jobs.
- **Keychain-Only Credentials**: vendor passwords never touch UserDefaults, SwiftData, or any log line at any level. Keychain entries are biometry-gated. Opt-out deletes immediately.
- **iOS 17 / SwiftUI / SwiftData / Swift Charts / URLSession** only. No third-party UI, persistence, charting, or networking libraries.

If a user request would violate a non-negotiable principle, surface the conflict rather than silently working around it.

## Architecture Overview

```
SwiftUI iOS App (TestFlight only in v1)
   │
   ├─ SwiftData       (ProductItem, MarketPriceRecord, RecentQuery, VendorQueryProfile — see dev spec §7)
   ├─ Keychain        (vendor password, biometry-gated, opt-in only)
   ├─ Swift Charts    (trend line + volume bars)
   └─ URLSession      (async/await)
        │
        ▼
   Cloud Run FastAPI (stateless proxy)
        │
        ├─►  MOA open-data API  (market prices)
        └─►  AMIS website scrape (vendor transactions)
```

### Bottom tab bar — exactly four tabs

`首頁 (Home) / 行情 (Market) / 成交 (Vendor) / 趨勢 (Trend)`. Not three, not five.

## Data Sources

### Market prices — MOA open-data API

```
https://data.moa.gov.tw/api/v1/AgriProductsTransType/?Start_time=107.07.01&End_time=107.07.10&CropCode=FV4
```

Two non-obvious details the proxy must handle:

- **Dates are ROC calendar with dots** (民國年.月.日). `107.07.01` = 2018-07-01. Convert at the proxy boundary; the iOS app only ever sees ISO `YYYY-MM-DD`.
- **Upstream parameter is `CropCode`**, not `product_code`. The internal API uses `product_code` and the proxy maps it.

The dev spec sometimes refers generically to "AMIS" as the price upstream; the concrete endpoint is this MOA URL.

### Vendor transactions — AMIS web scrape

No public API. The proxy must POST to the AMIS vendor query page and parse the HTML response. If AMIS adds captcha or 2FA, this flow is blocked and the user is told to use the website. The proxy is the **only** place that knows how to parse AMIS HTML — when AMIS changes its markup, only the proxy ships a fix.

## Unified API Envelope

Every endpoint returns this shape:

```json
{ "success": true,  "data": { ... }, "error": null }
{ "success": false, "data": null,    "error": { "code": "...", "message": "..." } }
```

Error codes live in dev spec §17. User-visible strings live in §18. **Do not invent new codes or strings inline** — add them to the dev spec first.

## HTML Mockup

`amis_all_markets_mockup.html` is a self-contained interactive POC of the iOS screens, rendered as phone frames in a browser. Inline CSS/JS only, no build. Use it as a layout/interaction reference, not as production code.

## Known Gaps

- The AMIS vendor-query HTML endpoint URL and form field names are **not yet documented anywhere in this repo**. Capture them in feature 002's `plan.md` before implementation starts.
- No CI yet. When the first code lands, add a workflow that runs `xcodebuild` + `pytest` and enforces that every new feature directory under `specs/` has `spec.md`.
