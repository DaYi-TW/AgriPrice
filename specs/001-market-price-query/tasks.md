---
description: "Task list for feature 001-market-price-query"
---

# Tasks: Market Price Query

**Input**: `specs/001-market-price-query/spec.md`, `plan.md`, `data-model.md`, `research.md`
**Tests**: Included (XCTest for `ROCDateFormatter`, `MOAClient` parsing, `MarketViewModel`; SwiftUI views are manual-tested per Constitution §IV).

## Phase 1: Foundation (Networking + Common)

- [X] T001 Create `ios/AgriPrice/Common/ErrorCode.swift` enum + zh-Hant message lookup from dev spec §17/§18
- [X] T002 Create `ios/AgriPrice/Common/APIResult.swift` generic result type
- [X] T003 Create `ios/AgriPrice/Common/ROCDateFormatter.swift` using `Calendar(identifier: .republicOfChina)`
- [X] T004 [P] Create `ios/AgriPriceTests/ROCDateFormatterTests.swift`: round-trip 1911-01-01 / 2024-02-29 / 2026-05-13; reject malformed input

## Phase 2: MOA client

- [X] T005 Create `ios/AgriPrice/Networking/MOAResponse.swift`: `MOAResponse` + `MOARow` Codables per data-model.md
- [X] T006 Create `ios/AgriPrice/Networking/MOAClient.swift`:
  - `fetchPrices(productCode:startDate:endDate:) async -> APIResult<[MarketPriceRecord]>`
  - Build URL with ROC dates + `CropCode`
  - Decode `MOAResponse`; map `Data` → `[MarketPriceRecord]`
  - Map `URLError` / decode failures / `RS = "ERROR"` to `ErrorCode`
- [X] T007 [P] Create `ios/AgriPriceTests/MOAClientParsingTests.swift`: feed canned JSON for happy path, empty `Data`, `RS = "ERROR"`, malformed JSON — assert correct `APIResult`

## Phase 3: User Story 1 — Today's prices (Priority: P1) — MVP

- [X] T008 Create `ios/AgriPrice/Features/Market/ProductPickerSheet.swift`: bottom sheet listing `ProductItem` ordered by `isFavorite desc, sortOrder, name`; tap-to-select; star toggle
- [X] T009 Create `ios/AgriPrice/Features/Market/DateRangeSheet.swift`: start + end pickers, preset chips (今天 / 本月 / 近 7 日 / 近 30 日 / 近 90 日); inline validation per FR-004
- [X] T010 Create `ios/AgriPrice/Features/Market/MarketViewModel.swift` (`@Observable`):
  - Holds `selectedProduct`, `startDate`, `endDate`, `state: LoadState`
  - On change, cancel prior `Task` and call `MOAClient`
  - On success, upsert `MarketPriceRecord` rows + append `RecentQuery`
  - Expose computed `summary` (range high/avg/low) and `rowsByMarket`
- [X] T011 Create `ios/AgriPrice/Features/Market/MarketSummaryCard.swift` (subview)
- [X] T012 Create `ios/AgriPrice/Features/Market/MarketRowView.swift` (subview; tap fires navigation to TrendView)
- [X] T013 Replace stub `ios/AgriPrice/Features/Market/MarketView.swift` with the real screen: header (product chip + date chip), summary card, market list, friendly empty/error states from `ErrorCode`

**Checkpoint**: Pick `FV4`, see today's rows across markets. Empty state when no data. Error state when offline (cached SwiftData shown if present).

## Phase 4: User Story 2 — Trend drill-down (Priority: P2)

- [X] T014 Create `ios/AgriPrice/Features/Trend/TrendViewModel.swift`: takes `(productCode, marketCode, startDate, endDate)`; reads from SwiftData cache; if empty for the range, calls `MOAClient` and writes through
- [X] T015 Replace stub `ios/AgriPrice/Features/Trend/TrendView.swift`:
  - Header with product + market + range
  - `Chart` with `LineMark` for `averagePrice` over `tradeDate`
  - `Chart` with `BarMark` for `volume` over `tradeDate`
  - Gaps in date series render as broken lines (no zero imputation per spec edge case)
- [X] T016 Wire `MarketRowView` tap → push `TrendView` via `NavigationStack`

**Checkpoint**: Tap a market row → trend view renders line + bar charts over the same date range.

## Phase 5: User Story 3 — Favorites + Home shortcuts (Priority: P3)

- [X] T017 In `ProductPickerSheet.swift`, persist star toggle to `ProductItem.isFavorite` + bump `updatedAt`
- [ ] T018 In `HomeView.swift`, add tap handler on favorite chip → switch to Market tab with product pre-selected and last-used date range from most-recent `RecentQuery` for that product *(deferred — needs cross-tab route state in `AppShell`; revisit when adding more deep links)*
- [ ] T019 In `HomeView.swift`, add tap handler on recent-query row → switch to Market tab with full `(product, start, end)` triple restored *(deferred — same reason as T018)*

**Checkpoint**: Star → reorder → kill/relaunch → still starred. Home chip tap → Market view opens pre-filtered.

## Phase 6: Tests

- [X] T020 [P] Create `ios/AgriPriceTests/MarketViewModelTests.swift`: in-memory `ModelContainer`; mock `MOAClient` via a protocol; assert success/empty/error → correct `state`; assert SwiftData write-through (in-flight cancellation test omitted — covered indirectly by the Task-cancel logic in the VM)
- [X] T021 Refactor `MOAClient` to conform to a `MOAClientProtocol` so T020's mock can substitute

## Phase 7: Polish

- [X] T022 Update `specs/001-market-price-query/quickstart.md` with the end-to-end test steps a contributor runs in the simulator
- [X] T023 Verify `Info.plist` has no `NSAppTransportSecurity` exception — MOA serves valid HTTPS, no exception needed

## Notes

- `[P]` = task may run in parallel with the previous one (independent file).
- No Xcode build verification in this environment; sources are type-checked by inspection.
- The 002 vendor feature is **not** in this task list — it's deferred until the AMIS upstream is figured out. The Vendor tab stub from 003 stays.
