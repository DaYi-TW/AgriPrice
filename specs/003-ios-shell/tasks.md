---
description: "Task list for feature 003-ios-shell"
---

# Tasks: iOS App Shell

**Input**: `specs/003-ios-shell/spec.md`, `plan.md`, `data-model.md`
**Tests**: Included (XCTest for HomeViewModel; SwiftUI views are manual-tested per constitution §IV).

## Phase 1: Setup

- [X] T001 Create `ios/AgriPrice/` directory tree per plan.md "Project Structure"
- [X] T002 Create empty `ios/.gitignore` excluding `*.xcodeproj/`, `DerivedData/`, `.swiftpm/`, `.build/`

## Phase 2: Foundational

- [X] T003 [P] [US2] Create `ios/AgriPrice/Models/ProductItem.swift` per dev spec §7.1
- [X] T004 [P] [US2] Create `ios/AgriPrice/Models/MarketPriceRecord.swift` per dev spec §7.2
- [X] T005 [P] [US2] Create `ios/AgriPrice/Models/RecentQuery.swift` per dev spec §7.3
- [X] T006 [P] [US2] Create `ios/AgriPrice/Models/VendorQueryProfile.swift` per dev spec §7.4
- [X] T007 [US2] Create `ios/AgriPrice/Resources/BundledProducts.json` (10 entries per data-model.md)
- [X] T008 [US2] Create `ios/AgriPrice/Common/DesignTokens.swift` (greens from mockup)
- [X] T009 [US2] Create `ios/AgriPrice/Common/ErrorScreen.swift` (SwiftData init failure UI)
- [X] T010 [US2] Create `ios/AgriPrice/AgriPriceApp.swift`: `@main` struct, build `ModelContainer` over the four models, seed `ProductItem` from `BundledProducts.json` on first launch, fall back to `ErrorScreen` on init failure

**Checkpoint**: SwiftData container initializes cleanly on cold start.

## Phase 3: User Story 1 — 4-tab shell + Home (Priority: P1) — MVP

- [X] T011 [US1] Create `ios/AgriPrice/AppShell.swift`: `TabView` with 4 `Tab`s — Home / Market / Vendor / Trend; per-tab `NavigationStack`
- [X] T012 [P] [US1] Create stub `ios/AgriPrice/Features/Market/MarketView.swift` ("市場行情 — 即將推出 (001)")
- [X] T013 [P] [US1] Create stub `ios/AgriPrice/Features/Vendor/VendorView.swift` ("今日成交 — 即將推出 (002)")
- [X] T014 [P] [US1] Create stub `ios/AgriPrice/Features/Trend/TrendView.swift` ("趨勢 — 即將推出 (001)")
- [X] T015 [US1] Create `ios/AgriPrice/Features/Home/HomeViewModel.swift`: derives favorites + recent queries from SwiftData. Cards show "—" when no data.
- [X] T016 [US1] Create `ios/AgriPrice/Features/Home/HomeView.swift`: hero card, 2x2 summary grid, 2 function cards, "常用品項" section (empty state when no favorites)

**Checkpoint**: App launches → Home renders → tab switches work, even before US3.

## Phase 4: User Story 3 — Favorites + recent queries on Home (Priority: P2)

- [X] T017 [US3] In `HomeViewModel.swift`, add `@Query` for `ProductItem` filtered by `isFavorite == true`, ordered by `sortOrder, name`
- [X] T018 [US3] In `HomeViewModel.swift`, add `@Query` for `RecentQuery` ordered by `queriedAt` desc, limited to 10
- [X] T019 [US3] In `HomeView.swift`, render "常用品項" chips bound to the favorites query
- [X] T020 [US3] In `HomeView.swift`, render "最近查詢" list bound to the recent-queries query

**Checkpoint**: With seeded favorites + recent queries, Home shows them; without, empty states.

## Phase 5: Tests

- [X] T021 [P] Create `ios/AgriPriceTests/HomeViewModelTests.swift`: in-memory `ModelContainer`, seed 3 favorites with sort orders, assert order; seed 2 recent queries with timestamps, assert most-recent-first.

## Phase 6: Polish

- [X] T022 Create `ios/AgriPrice/Info.plist` snippet documented in plan.md (light mode, iPhone-only)
- [X] T023 Update `specs/003-ios-shell/quickstart.md` with Xcode setup steps

## Notes

- All tasks marked `[X]` are completed by this implementation pass. The Xcode project file itself is **not** generated (no macOS in this environment); a future contributor wires the sources into Xcode.
- No build verification was possible in this environment. The Swift code is type-checked by inspection, not by `swiftc`.
