# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Status

This repository is a **standalone git repo** (`main` branch) initialized 2026-05-13. It contains specs, scaffolding, and an iOS Swift source tree under `ios/AgriPrice/` — but **no Xcode project is committed** (the dev environment is Windows; a macOS contributor wires the sources into Xcode 15+; see `specs/003-ios-shell/quickstart.md`).

There is **no backend code in this repo and no plan to add one in v1**. The iOS app talks directly to the MOA open-data API via `URLSession`.

Build/test/lint commands: not runnable in this Windows dev environment — Swift code is type-checked by inspection only. Once the project lands in Xcode, `xcodebuild test -scheme AgriPrice -destination 'platform=iOS Simulator,name=iPhone 15'` is the test command.

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
| 001 | `001-market-price-query` | Query market prices across all markets by product code + date range. iOS calls MOA directly. (MarketView, TrendView, MOAClient) |
| 003 | `003-ios-shell` | iOS app shell: 4-tab navigation, Home screen, SwiftData container. **Shipped.** |

A "002 vendor transactions" feature is deferred — the AMIS vendor API is not yet figured out. The Vendor tab is a stub in 003 and stays that way until the upstream is understood.

## Constitution Highlights (Non-Negotiable)

Read `.specify/memory/constitution.md` in full before any non-trivial change. The principles that have killed past designs:

- **On-Device First**: no Cloud SQL, no Firestore, no server-side user data. SwiftData on iPhone is the only persistence.
- **No Backend in v1**: iOS calls MOA directly via URLSession. There is no FastAPI proxy, no Cloud Run service, no sibling `api/` directory. ROC date conversion, JSON decoding, and error mapping all live in Swift.
- **Keychain-Only Credentials**: when the vendor feature lands, vendor passwords never touch UserDefaults, SwiftData, or any log line at any level. Keychain entries are biometry-gated. Opt-out deletes immediately.
- **iOS 17 / SwiftUI / SwiftData / Swift Charts / URLSession** only. No third-party UI, persistence, charting, or networking libraries.

If a user request would violate a non-negotiable principle, surface the conflict rather than silently working around it.

## Architecture Overview

```
SwiftUI iOS App (TestFlight only in v1)
   │
   ├─ SwiftData       (ProductItem, MarketPriceRecord, RecentQuery, VendorQueryProfile — see dev spec §7)
   ├─ Keychain        (vendor password, biometry-gated, opt-in only — deferred feature)
   ├─ Swift Charts    (trend line + volume bars)
   └─ URLSession      (async/await)
        │
        └─► MOA open-data API (https://data.moa.gov.tw/api/v1/AgriProductsTransType/)
```

No backend service exists. iOS handles ROC ↔ ISO date conversion, MOA JSON decoding, and error mapping locally.

### Bottom tab bar — exactly four tabs

`首頁 (Home) / 行情 (Market) / 成交 (Vendor) / 趨勢 (Trend)`. Not three, not five. The 成交 tab currently shows a "尚未開放" stub until the vendor data source is figured out.

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

### Vendor transactions — deferred

The AMIS vendor query flow needs login + HTML scraping, and the upstream URL / form fields aren't documented yet. The Vendor tab is a stub in 003. When the upstream is figured out, the vendor feature ships — and may force re-opening Constitution II if a proxy turns out to be unavoidable.

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

- The AMIS vendor-query upstream (URL, form fields, auth flow) is unknown. A vendor feature can't be specced until that's reverse-engineered.
- No CI yet. When the first code lands in a buildable Xcode project, add a workflow that runs `xcodebuild test` and enforces that every new feature directory under `specs/` has `spec.md`.
- No Xcode project file is committed. The first macOS contributor wires `ios/AgriPrice/` into a fresh project — `specs/003-ios-shell/quickstart.md` documents the steps.
