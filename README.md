# AgriPrice 農價通

iOS app for Taiwan agricultural-wholesale-market price lookup. Built for a small family/friends cohort (≤ 80 TestFlight users); not a public product.

- **Stack**: SwiftUI · SwiftData · Swift Charts · URLSession (iOS 17+)
- **Backend**: none. The app calls the [MOA open-data API](https://data.moa.gov.tw/api/v1/AgriProductsTransType/) directly.
- **Workflow**: GitHub Spec Kit 0.7.4 (specs under `specs/NNN-*/`)

## What it does

| Tab | Status | What |
|---|---|---|
| 首頁 Home | ✅ shipped (003) | Hero card, 2×2 summary grid, favorite chips, recent queries |
| 行情 Market | ✅ shipped (001) | Pick product + date range → today's prices across all wholesale markets, with range summary |
| 成交 Vendor | ⏸️ stub | Supplier login + own-transactions query — deferred until the AMIS upstream is reverse-engineered |
| 趨勢 Trend | ✅ shipped (001) | Line chart of avg price + bar chart of volume over the chosen range |

Bundled crops for v1: 辣椒(朝天椒 / 紅小 / 青小 / 青龍 / 糯米椒) · 甘藍(初秋 / 改良種) · 大蒜(蒜頭) · 青蔥(日蔥) · 洋蔥(本產).

## Repository layout

```
.
├── .specify/             # Spec Kit scaffolding (constitution, templates, scripts)
├── specs/                # Per-feature spec/plan/tasks
│   ├── 001-market-price-query/
│   └── 003-ios-shell/
├── ios/
│   ├── AgriPrice/        # Swift sources (Models / Features / Common / Networking / Resources)
│   └── AgriPriceTests/   # XCTest
├── agriprice_development_spec.md   # Legacy reference (SwiftData shapes §7, error codes §17, strings §18)
├── agriprice_proposal.md           # High-level motivation (non-authoritative)
├── amis_all_markets_mockup.html    # Interactive HTML POC of the screens
├── CLAUDE.md             # Guidance for Claude Code sessions
└── README.md             # This file
```

There is **no `api/` directory and no plan to add one** — see Constitution Principle II.

## Spec-driven workflow

Every feature flows through:

1. `/speckit-specify` → `specs/NNN-name/spec.md`
2. `/speckit-clarify` (optional)
3. `/speckit-plan` → `plan.md`
4. `/speckit-tasks` → `tasks.md`
5. `/speckit-implement`

The non-negotiables live in [`.specify/memory/constitution.md`](.specify/memory/constitution.md). Read it before any non-trivial change. Top of the list: on-device first, no backend in v1, Keychain-only for any future credentials, iOS-17-native stack only.

## Xcode setup

This repo holds Swift sources but **no `.xcodeproj`** — the dev environment that wrote the code is Windows. The first macOS contributor wires the sources into a fresh project:

### One-time

1. Open Xcode 15+ and create a new **iOS App** project named `AgriPrice` at `ios/AgriPrice.xcodeproj` with:
   - Interface: SwiftUI
   - Language: Swift
   - Minimum deployment: iOS 17.0
   - Targeted device family: iPhone only
2. Delete the auto-generated `AgriPriceApp.swift` and `ContentView.swift` that Xcode created.
3. In Finder, drag the **contents** of `ios/AgriPrice/` into the Xcode project navigator under the `AgriPrice` group:
   - `AgriPriceApp.swift`, `AppShell.swift`
   - The `Models/`, `Features/`, `Common/`, `Networking/`, `Resources/` folders
   - In the "Add files" sheet, untick "Copy items if needed" (they're already on disk) and tick the `AgriPrice` target.
4. **Info.plist**: in target build settings, set `INFOPLIST_FILE = AgriPrice/Info.plist` so the committed Info.plist (light mode + iPhone-only) is used. Do not let Xcode auto-generate one.
5. **BundledProducts.json**: select it, in the File Inspector make sure it's added to the **AgriPrice** target's `Copy Bundle Resources` build phase.
6. Add a **Unit Test target** named `AgriPriceTests` (File → New → Target). Drag the contents of `ios/AgriPriceTests/` into the test target.
7. `⌘B` to verify the project compiles, then `⌘U` to run the tests.

### Run

- Select scheme `AgriPrice`, simulator `iPhone 15`, `⌘R`.
- On cold launch you should land on the Home tab within ~1 s.
- Tap **行情** → tap the green product chip → pick `FV4 辣椒 朝天椒` → tap the date chip → "近 7 日" → confirm.
- Within ~5 s you should see a green summary card + one row per market that traded.
- Tap any market row → trend chart opens.

### Smoke checks

| Case | Expected |
|---|---|
| Pick a known-quiet date (e.g. a single Sunday) | `查無此日期區間行情` empty state (no error) |
| Turn off network, retry | `網路連線異常,請稍後再試` + cached previous result still visible |
| Star a product | It jumps to the top of the picker on relaunch |

For deeper detail see [`specs/003-ios-shell/quickstart.md`](specs/003-ios-shell/quickstart.md) and [`specs/001-market-price-query/quickstart.md`](specs/001-market-price-query/quickstart.md).

## Data source

MOA open-data, called directly from the app:

```
GET https://data.moa.gov.tw/api/v1/AgriProductsTransType/
    ?Start_time=107.07.01     ← ROC YYY.MM.DD (民國年.月.日)
    &End_time=107.07.10
    &CropCode=FV4              ← case-sensitive
```

Quirks the `MOAClient` absorbs:

- ROC ↔ ISO date conversion via `Calendar(identifier: .republicOfChina)`
- Case-sensitive `CropCode`
- `{RS: "OK", Data: []}` is a friendly empty state, not an error
- `{RS: "ERROR"}` maps to `INVALID_PRODUCT_CODE` per dev spec §17

## Known gaps

- No Xcode project committed (Windows dev env).
- No CI yet — wire `xcodebuild test` once a macOS contributor lands the project.
- AMIS vendor-query upstream not figured out — Vendor tab stays a stub.

## License

Personal-use project. No license granted for redistribution.
