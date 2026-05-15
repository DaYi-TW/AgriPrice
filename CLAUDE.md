# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Status

This repository is a **standalone git repo** (`main` branch) initialized 2026-05-13. It contains specs, scaffolding, and an iOS Swift source tree under `ios/AgriPrice/` — but **no Xcode project is committed** (the dev environment is Windows; a macOS contributor wires the sources into Xcode 15+ — see `README.md` § "Xcode setup" for the seven-step procedure, and `specs/003-ios-shell/quickstart.md` for smoke checks once it builds).

There is **no backend code in this repo and no plan to add one in v1**. The iOS app talks directly to the MOA open-data API via `URLSession`.

Build/test/lint commands: not runnable in this Windows dev environment — Swift code is type-checked by inspection only. Once the project lands in Xcode, the full test command is:

```
xcodebuild test -scheme AgriPrice -destination 'platform=iOS Simulator,name=iPhone 15'
```

XCTest sources live in `ios/AgriPriceTests/`: `ROCDateFormatterTests`, `MOAClientParsingTests`, `MarketViewModelTests`, `VendorAPIClientParsingTests`, `VendorViewModelTests`, `HomeViewModelTests`. Run one at a time with `-only-testing`, e.g.:

```
xcodebuild test -scheme AgriPrice -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AgriPriceTests/ROCDateFormatterTests
```

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

| # | Branch | Status | Spec |
|---|---|---|---|
| 001 | `001-market-price-query` | Shipped | Query market prices across all markets by product code + date range. iOS calls MOA directly. (MarketView, TrendView, MOAClient) |
| 002 | `002-vendor-transactions` | Shipped | Supplier login + today's transactions. iOS calls the `chill-api` Cloud Run service (separately maintained). |
| 003 | `003-ios-shell` | Shipped | iOS app shell: 4-tab navigation, Home screen, SwiftData container. |

## Constitution Highlights (Non-Negotiable)

Read `.specify/memory/constitution.md` in full before any non-trivial change. The principles that have killed past designs:

- **On-Device First**: no Cloud SQL, no Firestore, no server-side user data. SwiftData on iPhone is the only persistence.
- **No Backend Code in This Repo**: iOS calls upstream services directly via URLSession. MOA open-data for market prices (001); `chill-api` Cloud Run for vendor scraping (002, separately maintained — not in this repo). There is no `api/` directory and no plan to add one.
- **Keychain-Only Credentials**: vendor passwords (feature 002, shipped) live only in biometry-gated Keychain entries. They never touch UserDefaults, SwiftData, or any log line at any level. Opt-out deletes immediately. See `ios/AgriPrice/Common/KeychainStore.swift` and `BiometryAvailability.swift`.
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
        ├─► MOA open-data API           (market prices — feature 001)
        │   https://data.moa.gov.tw/api/v1/AgriProductsTransType/
        │
        └─► chill-api Cloud Run service (vendor scraping — feature 002, separately maintained)
            https://chill-api-240848983153.asia-east1.run.app/api/scrape
```

No backend code lives in this repo. iOS handles ROC ↔ ISO date conversion, MOA JSON decoding, and error mapping locally. The chill-api service is treated as an external black box — its request/response shape is documented in `specs/002-vendor-transactions/data-model.md`.

### iOS source-tree map

```
ios/AgriPrice/
├── AgriPriceApp.swift         # @main, SwiftData ModelContainer wiring
├── AppShell.swift             # TabView with the four tabs
├── Models/                    # SwiftData @Model types (dev spec §7)
├── Features/                  # One folder per tab: Home/, Market/, Vendor/, Trend/
│                              #   each ships its own View + ViewModel
├── Common/                    # APIResult, ErrorCode, DesignTokens, ROCDateFormatter,
│                              #   KeychainStore, BiometryAvailability, ErrorScreen
├── Networking/                # MOAClient, VendorAPIClient + their response DTOs
└── Resources/                 # BundledProducts.json (must be in Copy Bundle Resources)
```

### Bottom tab bar — exactly four tabs

`首頁 (Home) / 行情 (Market) / 成交 (Vendor) / 趨勢 (Trend)`. Not three, not five.

## Data Sources

### Market prices — MOA open-data API (called directly from iOS)

```
https://data.moa.gov.tw/api/v1/AgriProductsTransType/?Start_time=107.07.01&End_time=107.07.10&CropCode=FV4
```

Two non-obvious details Swift code must handle:

- **Dates are ROC calendar with dots** (民國年.月.日). `107.07.01` = 2018-07-01. The conversion (`ISO → ROC` on the request, `ROC → ISO` on the response) lives in a Swift helper. UI code only ever touches `Date` / ISO `YYYY-MM-DD`.
- **Query parameter is `CropCode`** with `FV4` etc. — capitalized as shown. Don't lowercase it; the upstream is case-sensitive in our experience.

Verified response shape (live, 2026-05-13):
```json
{"RS":"OK","Data":[{"TransDate":"107.07.02","CropCode":"FV4","CropName":"辣椒-朝天椒","MarketCode":"104","MarketName":"台北一","Upper_Price":146.7,"Middle_Price":120,"Lower_Price":100,"Avg_Price":121.7,"Trans_Quantity":2080}, ...]}
```

When `Data` is `[]` (no transactions for the date range), show the friendly empty-state, not an error.

### Vendor transactions — chill-api Cloud Run service

```
POST https://chill-api-240848983153.asia-east1.run.app/api/scrape
Content-Type: application/json

{"credentials": {"supply_no": "...", "supply_sub": "...", "password": "..."}}
```

Response envelope (success or error, both 200/401/500/502):

```json
{
  "success": true,
  "message": "數據獲取成功" | "今天無銷售資料",
  "timestamp": "2026-05-13T13:54:49.495366",
  "data": {"total_profit": 777, "year_total": 333666, "market_data": [...]},
  "error_code": null
}
```

| HTTP | error_code     | Trigger                                                    |
|------|----------------|------------------------------------------------------------|
| 200  | null           | Success (data populated or `market_data: []`)              |
| 401  | AUTH_FAILED    | AMIS rejected credentials                                  |
| 502  | UPSTREAM_ERROR | AMIS timeout / scraper failed                              |
| 500  | INTERNAL_ERROR | Anything else                                              |
| 422  | (FastAPI raw)  | `{"detail":[...]}` — malformed request body; treat as INTERNAL_ERROR client-side |

The service is maintained in a separate repo. When its shape changes, this app ships an update. Never log the request body (it carries the password).

## Internal error envelope

For consistency with dev spec §17/§18, the iOS layer wraps every async operation in this shape:

```swift
enum APIResult<T> {
    case success(T)
    case failure(code: ErrorCode, message: String)
}
```

`ErrorCode` strings come from dev spec §17. User-visible messages come from §18. **Do not invent new codes or strings inline** — add them to the dev spec first.

## HTML Mockup

`amis_all_markets_mockup.html` is a self-contained interactive POC of the iOS screens, rendered as phone frames in a browser. Inline CSS/JS only, no build. Use it as a layout/interaction reference, not as production code.

## Known Gaps

- The chill-api service's repo / contact / on-call story is undocumented here. If it changes shape, the only signal is iOS errors. Capture the owner in `specs/002-vendor-transactions/plan.md` if you find out.
- No CI yet. When the first code lands in a buildable Xcode project, add a workflow that runs `xcodebuild test` and enforces that every new feature directory under `specs/` has `spec.md`.
- No Xcode project file is committed. The first macOS contributor wires `ios/AgriPrice/` into a fresh project — see `README.md` § "Xcode setup" for the seven-step procedure (`INFOPLIST_FILE` build setting, adding `BundledProducts.json` to Copy Bundle Resources, creating the `AgriPriceTests` target). `specs/003-ios-shell/quickstart.md` covers smoke checks once it builds.
