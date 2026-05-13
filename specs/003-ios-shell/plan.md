# Implementation Plan: iOS App Shell

**Branch**: `003-ios-shell` | **Date**: 2026-05-13 | **Spec**: [./spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-ios-shell/spec.md`

## Summary

Stand up the iOS app skeleton so features 001 and 002 have somewhere to plug into: a SwiftUI app target, a `TabView` with four tabs (首頁 / 行情 / 成交 / 趨勢), a Home screen with hero + summary + function cards + favorites, and a SwiftData `ModelContainer` wired with the four models from dev spec §7. No real data yet — Home cards show "—" placeholders and other tabs are stub views that features 001/002 replace.

## Technical Context

**Language/Version**: Swift 5.9 (iOS 17.0 SDK)
**Primary Dependencies**: SwiftUI, SwiftData, Swift Charts (placeholder import; only used by 001 trend later), URLSession (placeholder; no calls in 003)
**Storage**: SwiftData on-device. Models: `ProductItem`, `MarketPriceRecord`, `RecentQuery`, `VendorQueryProfile` (dev spec §7).
**Testing**: XCTest. Unit tests for `HomeViewModel` derivations from seeded SwiftData. Manual TestFlight smoke for SwiftUI views (per constitution §IV exemption).
**Target Platform**: iOS 17.0+, iPhone only (no iPad target), light mode locked.
**Project Type**: Mobile app (iOS) — Swift Package Manager layout under `ios/` so the API project can land later under `api/` without restructuring.
**Performance Goals**: Cold start to interactable Home < 2 s on iPhone 13 (SC-001). Tab switch < 200 ms (SC-004).
**Constraints**: zh-Hant strings only in shipped UI. No third-party UI / persistence / charting libs (Constitution V).
**Scale/Scope**: ≤ 80 TestFlight users. Single device per user. No iCloud sync in v1.

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. On-Device First | PASS | All shell state is SwiftData. No backend reach in 003. |
| II. Stateless Proxy | N/A | No backend touched in this feature. |
| III. Keychain-Only Credentials | PASS | 003 does not handle vendor credentials. Stubs the Vendor tab; 002 owns Keychain wiring. |
| IV. Spec-Driven Development | PASS | This plan + tasks.md will gate implementation. |
| V. iOS 17 + SwiftUI + SwiftData + Swift Charts | PASS | Stack matches exactly. Swift Charts is imported but unused in 003. |
| VI. Friendly Error States | PASS | SwiftData init failure → user-facing error screen (FR-005), not crash. |
| VII. Simplicity | PASS | No state management library, no DI framework. `@Environment(\.modelContext)` is enough. |

**Gate**: PASS. No complexity tracking needed.

## Project Structure

### Documentation

```text
specs/003-ios-shell/
├── plan.md              # this file
├── spec.md              # already exists
├── data-model.md        # SwiftData models verbatim from dev spec §7
├── quickstart.md        # how to open the Xcode project once 003 is implemented
└── tasks.md             # produced by /speckit-tasks
```

No `contracts/` directory — this feature has no API contracts.

### Source Code

```text
ios/
├── AgriPrice/
│   ├── AgriPriceApp.swift           # @main, SwiftData ModelContainer, AppShell
│   ├── AppShell.swift               # TabView with 4 tabs
│   ├── Models/
│   │   ├── ProductItem.swift        # dev spec §7.1
│   │   ├── MarketPriceRecord.swift  # dev spec §7.2
│   │   ├── RecentQuery.swift        # dev spec §7.3
│   │   └── VendorQueryProfile.swift # dev spec §7.4
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   ├── Market/
│   │   │   └── MarketView.swift     # stub: "市場行情 (Coming soon — 001)"
│   │   ├── Vendor/
│   │   │   └── VendorView.swift     # stub: "今日成交 (Coming soon — 002)"
│   │   └── Trend/
│   │       └── TrendView.swift      # stub: "趨勢 (Coming soon — 001)"
│   ├── Common/
│   │   ├── DesignTokens.swift       # colors from mockup (#188046, #dff0e2, …)
│   │   └── ErrorScreen.swift        # SwiftData init failure UI
│   └── Resources/
│       └── BundledProducts.json     # seed data for ProductItem on first launch
├── AgriPriceTests/
│   └── HomeViewModelTests.swift
└── AgriPrice.xcodeproj/             # generated locally; NOT committed in 003
```

**Structure Decision**: Top-level `ios/` for the iOS app. A sibling `api/` directory will be added by feature 001 for FastAPI. The Xcode project file is NOT committed because this dev environment is Windows (no Xcode); a future macOS contributor regenerates it from the Swift sources or via Tuist/XcodeGen (out of scope for v1; sources are committed as a Swift Package–friendly layout).

## Phase 0: Research

`research.md` is not needed — the spec and dev spec §7 already pin every technical decision (iOS 17, SwiftData, four models). No `NEEDS CLARIFICATION` items remain.

## Phase 1: Design

### data-model.md

The four `@Model` types from dev spec §7.1–§7.4 are copied verbatim. The only addition is a first-launch seed: `BundledProducts.json` is read at app launch, and for each entry without an existing `ProductItem` row, one is inserted with `isFavorite=false`, `sortOrder=index`.

### quickstart.md

Will document: clone, open `ios/AgriPrice` in Xcode 15+, set the simulator to iPhone 15, ⌘R. (Written when implementation lands; placeholder for now.)

### Constitution re-check after design

No violations. The design uses only Apple-native frameworks and on-device persistence.

## Cross-cutting decisions

- **No DI container.** `@Environment(\.modelContext)` is used directly; view models receive context via init from the view.
- **No state management library.** SwiftUI's `@State`, `@Bindable`, `@Query` are sufficient.
- **Bundled product seed** is checked in as JSON at `ios/AgriPrice/Resources/BundledProducts.json` with the v1 crop list from dev spec §6.3.
- **Light mode lock** is enforced via `Info.plist` `UIUserInterfaceStyle = Light`.
- **iPhone-only** is enforced via `TARGETED_DEVICE_FAMILY = 1`.

## Risks

1. **Cannot build locally.** This dev environment has no Xcode. The Swift sources are written but not compiled; the first macOS contributor needs to wire them into a real Xcode project. → Mitigation: commit sources in a Swift Package–style layout so an `xcodegen` or manual Xcode "Add Files" produces a buildable target without code changes.
2. **SwiftData migration on schema change** is unaddressed. → Accepted: v1 schema is small and stable; defer to future amendment.
