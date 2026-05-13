# Feature Specification: iOS App Shell

**Feature Branch**: `003-ios-shell`
**Created**: 2026-05-13
**Status**: Draft
**Input**: User description: "iOS app shell: 4-tab navigation, Home screen, SwiftData scaffolding"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - App opens and shows a working Home with 4 tabs (Priority: P1)

A first-time user launches AgriPrice. Within 2 seconds they land on the Home tab, see a green hero card ("今日焦點"), four summary cards (全市場均價 / 今日漲跌 / 最高市場 / 最低市場), two function entry cards (行情 / 成交), and a "常用品項" empty state. The bottom tab bar has four tabs: 首頁 / 行情 / 成交 / 趨勢. Tapping any tab navigates without crashing.

**Why this priority**: The shell is a prerequisite for features 001 and 002. Until the tab bar and Home exist, the rest of the app can't be reached.

**Independent Test**: Build and launch the app on iOS 17 simulator. Confirm cold-start to Home is under 2 s, all four tabs are present and switchable, and Home cards render even with empty/placeholder data.

**Acceptance Scenarios**:

1. **Given** a fresh install on iOS 17, **When** the user taps the app icon, **Then** within 2 s they see the Home screen with hero + summary cards + function cards + "常用品項".
2. **Given** the user is on Home, **When** they tap any of the four bottom tabs, **Then** the corresponding view appears (placeholder views are acceptable in this story for tabs whose features aren't built yet).
3. **Given** the user has never run the app before, **When** they reach Home, **Then** the "常用品項" section shows a friendly empty state ("尚未收藏品項,前往行情頁加入") with a button into the Market tab.

---

### User Story 2 - SwiftData container loads on launch and survives upgrades (Priority: P1)

The SwiftData container is initialized at app launch with the four models (`ProductItem`, `MarketPriceRecord`, `RecentQuery`, `VendorQueryProfile`) per dev spec §7. When the user upgrades the app (e.g. via TestFlight), existing favorites and recent queries persist; no migration error blocks launch.

**Why this priority**: P1 because if SwiftData fails to initialize, the app cannot start. Features 001 and 002 both depend on the container being available before any view loads.

**Independent Test**: Launch the app, programmatically insert a `ProductItem` with `isFavorite=true`, kill, relaunch. Confirm the object is still queryable. Then bump the app version, install over the top, and confirm it still loads.

**Acceptance Scenarios**:

1. **Given** the app has never run, **When** it launches, **Then** the SwiftData container is created with the four models and no error is logged.
2. **Given** the user has favorited 3 products, **When** they upgrade the app to a new build with the same schema, **Then** the 3 favorites are still present.
3. **Given** SwiftData initialization fails for any reason (e.g. disk full), **When** the app launches, **Then** the user sees a clear error screen instructing them to free space and restart — not a silent white screen or crash.

---

### User Story 3 - Home surfaces favorites and recent queries (Priority: P2)

Once the user has favorites and recent queries (from feature 001), Home shows a "常用品項" horizontal chip row and a "最近查詢" list. Tapping a chip jumps to Market with that product pre-selected; tapping a recent query jumps to Market with both product and date range pre-set.

**Why this priority**: Quality of life on top of the shell. Story 1's empty state is acceptable v1; this turns Home into a real launcher.

**Independent Test**: Manually seed 3 favorites + 2 recent queries into SwiftData; relaunch and confirm both sections render with correct content and the taps navigate correctly.

**Acceptance Scenarios**:

1. **Given** the user has 3 favorites, **When** Home renders, **Then** the "常用品項" row shows 3 chips ordered by `sortOrder`, then `name`.
2. **Given** the user has 2 recent queries within the last 30 days, **When** Home renders, **Then** the "最近查詢" list shows them most-recent first.
3. **Given** the user taps a recent query chip, **When** they land on Market, **Then** both the product and the date range match the chip.

---

### Edge Cases

- **iOS < 17** — SwiftData is unavailable; the app refuses to install (set deployment target to 17.0). No runtime fallback needed.
- **Device language is not zh-Hant** — UI strings still display Chinese for v1 (no localization). System chrome may be English; that's acceptable.
- **Dynamic Type at the largest accessibility size** — Home cards must wrap, not truncate; tab labels may scale down to fit but icons stay readable.
- **Dark Mode** — Home colors are defined in the mockup with hard-coded greens (`#188046`, `#dff0e2`). v1 ships light-only; force a light appearance at the app level.
- **iPad** — Out of scope; mark the app iPhone-only.
- **First launch with no network** — Home still renders; summary cards show "—" placeholders, not errors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: App MUST use SwiftUI as the UI framework and target iOS 17.0+.
- **FR-002**: Root view MUST be a `TabView` with exactly four tabs in this order: 首頁 (Home), 行情 (Market), 成交 (Vendor), 趨勢 (Trend).
- **FR-003**: Home view MUST render: an "今日焦點" hero card, a 2×2 grid of summary cards (均價 / 漲跌 / 最高市場 / 最低市場), two function cards (行情 / 成交), and a "常用品項" section.
- **FR-004**: App MUST initialize a SwiftData `ModelContainer` at launch with the four models from dev spec §7: `ProductItem`, `MarketPriceRecord`, `RecentQuery`, `VendorQueryProfile`.
- **FR-005**: App MUST handle SwiftData initialization failure with a user-facing error screen, not a crash.
- **FR-006**: Home MUST show empty states for "常用品項" and "最近查詢" when SwiftData has none of the relevant rows.
- **FR-007**: App MUST be iPhone-only (no iPad target), light-mode-locked for v1.
- **FR-008**: App MUST present zh-Hant strings throughout the user-visible UI; no English placeholders in shipped builds.
- **FR-009**: Tab switches MUST preserve per-tab navigation stack (Market in a nested detail stays there when the user toggles to Vendor and back).
- **FR-010**: Cold start time from launch to first interactable Home frame MUST be under 2 seconds on an iPhone 13 or newer (dev spec §22 NFR).

### Key Entities

- **AppShell**: Root SwiftUI scene wiring the SwiftData container and the four-tab `TabView`.
- **HomeViewModel**: Reads favorites and recent queries from SwiftData and exposes them to `HomeView`.
- **ProductItem / MarketPriceRecord / RecentQuery / VendorQueryProfile**: Defined verbatim from dev spec §7.1–§7.4.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cold-start to interactable Home is **under 2 seconds** on iPhone 13 (dev spec §22 NFR).
- **SC-002**: SwiftData container init failure rate in TestFlight crash reports is **zero** over the pilot.
- **SC-003**: 100% of user-visible strings on Home and the four tabs are zh-Hant in the shipped build (English literals only allowed in code).
- **SC-004**: Tab switching between any pair of tabs takes **under 200 ms** with no flicker on a release build.

## Assumptions

- The app is distributed via **TestFlight only** in v1; App Store public listing is a v1.1 concern.
- The dev spec §7 SwiftData model shapes are stable. Any schema change after v1 will use SwiftData lightweight migration; manual versioning is not in scope for the shell.
- The Home mockup in `amis_all_markets_mockup.html` is the design reference for layout proportions, but colors and spacing may be adjusted to fit native iOS spacing tokens.
- Bundled product list (loaded into SwiftData on first launch) is the source of truth for "what products exist"; we are not building a `/api/v1/products` fetcher in v1.
- No analytics, no crash reporter beyond Apple's built-in TestFlight crash logs in v1.
- No account system — favorites and credentials are per-device, not synced to iCloud.
