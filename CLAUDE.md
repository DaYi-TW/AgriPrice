# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Status

This repository currently contains **only specification documents and an HTML mockup** — no Swift or Python source code exists yet. The implementation (planned as two separate repos: `agriprice-ios` and `agriprice-api`) has not been started.

Files in the directory:
- `agriprice_proposal.md` — high-level product proposal (中文)
- `agriprice_development_spec.md` — detailed iOS + API + backend spec (中文)
- `amis_all_markets_mockup.html` — standalone interactive HTML mockup of the iOS UI (open directly in a browser; no build step)

Note: this directory is **not** a git repo of its own. The parent `D:/Side Project` is a git repo that tracks a different project (Business Analysis); AgriPrice files are currently untracked there.

## Product Overview

AgriPrice (農價通) is a planned **iOS-only** app for querying Taiwan agricultural wholesale market prices. Two primary user flows:

1. **Market prices** — given an AMIS product code (e.g. `FV4` 辣椒 朝天椒) and a date range, show prices across all markets, with ranking and trend.
2. **Vendor transactions** — supplier logs in with `supplierCode + subCode + password` to see today's actual sales (per-market totals + per-item detail).

The product is intentionally scoped for **a small number of family/friends users**, which drives several architectural decisions (see below).

## Architecture (Planned)

```
SwiftUI iOS App  ──►  Cloud Run FastAPI proxy  ──►  AMIS / MOA open-data
   │
   ├─ SwiftData       (local cache: price records, favorites, recent queries)
   ├─ Keychain        (vendor credentials only — never UserDefaults, never SwiftData)
   └─ Swift Charts    (trend lines + volume bars)
```

Key architectural decisions — these are deliberate, do not "fix" them by adding cloud storage:

- **No Cloud SQL / Firestore.** All persistence is on-device via SwiftData. This is to keep GCP cost near-zero and avoid DB ops burden. Only revisit if the user base grows beyond family/friends.
- **Cloud Run is a stateless proxy.** It fetches from AMIS / MOA, parses, normalizes to the unified API response shape, and returns. It does **not** persist anything, especially not vendor credentials.
- **iOS minimum is iOS 17** (SwiftData requirement).
- **Bottom tab bar has exactly 4 tabs**: Home / Market / Vendor / Trend (首頁 / 行情 / 成交 / 趨勢).

## Data Sources

### Market prices — MOA open data API (the actual endpoint to use)

```
https://data.moa.gov.tw/api/v1/AgriProductsTransType/?Start_time=107.07.01&End_time=107.07.10&CropCode=FV4
```

Two things that trip people up:
- **Dates are ROC calendar with dots**, not ISO. `107.07.01` = 2018-07-01. The proxy must convert between user-facing `YYYY-MM-DD` and `民國YYY.MM.DD`.
- **Parameter is `CropCode`**, not `product_code`. The internal API spec uses `product_code` — the proxy maps it to `CropCode` when calling MOA.

The dev spec (sections 10–11) sometimes refers generically to "AMIS"; the concrete upstream is this MOA endpoint.

### Vendor transactions

No public API — the proxy must scrape/POST to the AMIS vendor query page. Password handling rules in section 19/20 of the dev spec are strict: **never log, never persist server-side, never store in UserDefaults or SwiftData**. Keychain is the only allowed client-side store.

## Unified API Response Shape

Every endpoint returns this envelope (success and error variants):

```json
{ "success": true,  "data": { ... }, "error": null }
{ "success": false, "data": null,    "error": { "code": "...", "message": "..." } }
```

Error codes defined in spec §17: `INVALID_PRODUCT_CODE`, `INVALID_DATE_RANGE`, `AMIS_QUERY_FAILED`, `AMIS_PARSE_FAILED`, `VENDOR_AUTH_FAILED`, `VENDOR_QUERY_FAILED`, `NETWORK_ERROR`, `UNKNOWN_ERROR`.

## Working with the Specs

When the user asks to "implement X" or "scaffold Y":
- The **single source of truth** is `agriprice_development_spec.md`. The proposal is high-level motivation; the spec has the concrete model definitions, screen list, endpoint contracts, and acceptance criteria.
- SwiftData models (`ProductItem`, `MarketPriceRecord`, `RecentQuery`, `VendorQueryProfile`) are defined in spec §7 with full Swift source — copy them verbatim unless the user asks to change the shape.
- The planned FastAPI layout is in spec §14. Endpoints: `/api/v1/market-prices`, `/api/v1/market-prices/trend`, `/api/v1/products`, `/api/v1/vendor/transactions`.
- The product code table can be **bundled into the iOS app** for v1 (spec §12.1 note) — `/api/v1/products` is optional in MVP.

## HTML Mockup

`amis_all_markets_mockup.html` is a self-contained interactive POC of the iOS screens (rendered as phone frames in a browser). It uses inline CSS/JS only — no build, no dependencies. Open it directly. Treat it as a visual reference for layout and interaction, not as production code.
