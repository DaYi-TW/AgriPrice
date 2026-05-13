# Implementation Plan: Market Price Query

**Branch**: `001-market-price-query` | **Date**: 2026-05-13 | **Spec**: [./spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-market-price-query/spec.md`

## Summary

Wire the Market and Trend tabs to live MOA open-data. iOS calls `https://data.moa.gov.tw/api/v1/AgriProductsTransType/` directly via `URLSession`; a Swift `MOAClient` handles ISO ↔ ROC date conversion, JSON decoding of the `{RS, Data}` envelope, and typed error mapping. Results are cached in SwiftData (`MarketPriceRecord`) so the last successful query survives offline. Picking a market row opens TrendView with a Swift Charts line+bar chart over the chosen range.

## Technical Context

**Language/Version**: Swift 5.9 (iOS 17.0 SDK)
**Primary Dependencies**: SwiftUI, SwiftData, Swift Charts, URLSession (all Apple-native; Constitution V)
**Storage**: SwiftData (`MarketPriceRecord`, `RecentQuery`, `ProductItem`). No file cache, no `URLCache` tuning.
**Networking**: `URLSession.shared.data(from:)` with `async/await`. No third-party HTTP library.
**Testing**: XCTest. Unit tests for `ROCDateFormatter`, `MOAClient` parsing (with canned JSON fixtures), error-mapping logic. SwiftUI views are manual-tested per Constitution §IV exemption.
**Target Platform**: iOS 17.0+, iPhone only, light mode locked (Info.plist set by 003).
**Project Type**: Mobile (iOS only). No `api/` directory exists or will be created.
**Performance Goals**: Cold start to Home interactable < 2 s (003 already meets). Market query render < 5 s on LTE (SC-001 tightens to 3 s when cached).
**Constraints**: zh-Hant strings only. HTTPS only. No third-party libs.
**Scale/Scope**: ≤ 80 TestFlight users; one device per user; no iCloud sync.

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. On-Device First | PASS | Results cached in SwiftData; no server-side user data. |
| II. No Backend in v1 | PASS | iOS calls MOA directly. Zero server-side code. |
| III. Keychain-Only Credentials | N/A | No vendor credentials in 001. |
| IV. Spec-Driven Development | PASS | spec.md + this plan + tasks.md gate implementation. |
| V. iOS 17 + SwiftUI + SwiftData + Swift Charts + URLSession | PASS | Stack matches. |
| VI. Friendly Error States | PASS | `ErrorCode` mapped to dev spec §18 zh-Hant strings; raw `URLError` never reaches UI. |
| VII. Simplicity | PASS | No DI container, no Combine glue, no state library. `@Observable` view model + `@Query`. |

**Gate**: PASS. No complexity tracking.

## Project Structure

### Documentation

```text
specs/001-market-price-query/
├── plan.md          # this file
├── spec.md          # already exists
├── data-model.md    # request/response shapes + ErrorCode table
├── quickstart.md    # how to exercise the Market tab end-to-end
├── research.md      # MOA endpoint quirks (ROC dates, case sensitivity)
└── tasks.md         # produced by /speckit-tasks
```

No `contracts/` directory — there is no service contract to lock down, just an upstream API we adapt to.

### Source Code (extends 003's tree)

```text
ios/AgriPrice/
├── Common/
│   ├── ROCDateFormatter.swift     # NEW: ISO ↔ ROC `YYY.MM.DD`
│   ├── ErrorCode.swift            # NEW: enum mirroring dev spec §17
│   └── APIResult.swift            # NEW: <T> result with typed error
├── Networking/
│   ├── MOAClient.swift            # NEW: URLSession wrapper; the only place that knows the MOA URL
│   └── MOAResponse.swift          # NEW: Codable matching {RS, Data: [MOARow]}
├── Features/
│   ├── Market/
│   │   ├── MarketView.swift             # REPLACES 003 stub
│   │   ├── MarketViewModel.swift        # NEW: orchestrates picker + date sheet + MOAClient + SwiftData cache
│   │   ├── ProductPickerSheet.swift     # NEW
│   │   ├── DateRangeSheet.swift         # NEW
│   │   ├── MarketSummaryCard.swift      # NEW (small subview)
│   │   └── MarketRowView.swift          # NEW (small subview)
│   └── Trend/
│       ├── TrendView.swift              # REPLACES 003 stub
│       └── TrendViewModel.swift         # NEW: derives chart series from cached MarketPriceRecord
└── Features/Home/
    └── HomeViewModel.swift              # MODIFY: add tap-to-prefill for favorites → Market tab
ios/AgriPriceTests/
├── ROCDateFormatterTests.swift          # NEW
├── MOAClientParsingTests.swift          # NEW (uses canned JSON)
└── MarketViewModelTests.swift           # NEW (in-memory ModelContainer)
```

**Structure Decision**: Slot new sources alongside 003's tree under `ios/AgriPrice/`. A new `Networking/` directory hosts the MOA client and its DTOs — the only Swift code in the repo that knows the MOA URL exists. Everything above it (`MarketViewModel`, views) talks in ISO `Date` and the SwiftData `MarketPriceRecord` shape.

## Phase 0: Research

`research.md` captures three MOA quirks that aren't obvious from a casual read of the endpoint:

1. **ROC dates with dots** — `107.07.01` = 2018-07-01. Year = Gregorian − 1911; month and day are zero-padded; separator is `.` not `-`.
2. **CropCode is case-sensitive** — `FV4` works, `fv4` returns `RS = "ERROR"` (verified live 2026-05-13).
3. **`CropName` contains a hyphen** (`辣椒-朝天椒`), not a space. The bundled `BundledProducts.json` uses a space (`辣椒 朝天椒`) for display — we keep our local names, we don't echo MOA's.

## Phase 1: Design

### data-model.md

Documents the MOA response shape, our internal `MOAClient` request/result types, the `ErrorCode` enum (mirrored from dev spec §17), and the mapping from `MOARow` → `MarketPriceRecord` (dev spec §7.2).

### Constitution re-check after design

No violations. Networking is pure URLSession; persistence is pure SwiftData; charts are pure Swift Charts.

## Cross-cutting decisions

- **MOAClient is a class, not an actor.** A single shared instance is fine — `URLSession.shared` is already thread-safe and there's no shared mutable state inside the client.
- **Request cancellation** uses Swift's `Task` cancellation, surfaced via `Task.checkCancellation()` after the network call returns.
- **In-flight de-dup**: the view model keeps the current `Task` handle and cancels it before starting a new one — no `OperationQueue`, no Combine.
- **SwiftData cache** is a write-through cache: every successful MOA response upserts `MarketPriceRecord` rows keyed by `(productCode, marketCode, tradeDate)`. On a fresh launch without network, the view reads from the cache.
- **No `URLCache`** — SwiftData is our cache. Two cache layers would be confusing for a one-developer codebase.

## Risks

1. **MOA endpoint stability** — MOA is a government open-data service; SLA is "best effort". Mitigation: cache aggressively in SwiftData; the friendly empty/error states keep the UI usable when MOA is down.
2. **Volume of returned rows** — a 90-day query for an active crop can return hundreds of rows. Mitigation: TrendView aggregates client-side; lists use `LazyVStack`/`List` for virtualization.
3. **ROC date parsing bugs around year boundaries** — handle leap years and the 1911 offset with `Calendar(identifier: .republicOfChina)` rather than hand-rolling arithmetic. Tests cover Jan 1 / Dec 31 / leap day.
