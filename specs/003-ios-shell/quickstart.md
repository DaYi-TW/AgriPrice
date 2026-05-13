# Quickstart: iOS App Shell

This feature's sources live in `ios/AgriPrice/`. There is **no Xcode project committed** — a future macOS contributor wires the sources into an Xcode 15+ project (iOS 17.0 deployment target).

## One-time setup (macOS contributor)

1. Open Xcode 15+ and create a new iOS App project named `AgriPrice` at `ios/AgriPrice.xcodeproj` with:
   - Interface: SwiftUI
   - Language: Swift
   - Minimum deployment: iOS 17.0
   - Targeted device family: iPhone only
2. Delete the auto-generated `AgriPriceApp.swift` and `ContentView.swift`.
3. Drag the contents of `ios/AgriPrice/` (sources + `Resources/`) into the Xcode project, **except** `Info.plist` (use the version in this repo by setting the target's `INFOPLIST_FILE` build setting to `AgriPrice/Info.plist`).
4. Add `BundledProducts.json` to the app target's **Copy Bundle Resources** build phase.
5. Add a test target `AgriPriceTests` and drag `ios/AgriPriceTests/HomeViewModelTests.swift` into it.
6. Build and run on iPhone 15 simulator (⌘R).

## What you should see

- Cold launch lands on the Home tab within ~1 s.
- Bottom tab bar shows 首頁 / 行情 / 成交 / 趨勢.
- Home shows the green hero card, 2×2 summary grid (all "—"), two function cards, and two "尚無" empty states (常用品項 + 最近查詢).
- Tapping any tab switches without delay.

## What is NOT in this feature

- No real data fetching (feature 001 + 002).
- No product picker UI (feature 001 will add `ProductPickerSheet`).
- No vendor login (feature 002).
- No charts (feature 001 trend).
