# Quickstart: Market Price Query

Prereq: `specs/003-ios-shell/quickstart.md` is already wired up in Xcode.

## Add 001's sources to the Xcode project

1. In Xcode's project navigator, drag these new folders into the `AgriPrice` group (uncheck "Copy items if needed" — they're already on disk):
   - `ios/AgriPrice/Common/ROCDateFormatter.swift`
   - `ios/AgriPrice/Common/ErrorCode.swift`
   - `ios/AgriPrice/Common/APIResult.swift`
   - `ios/AgriPrice/Networking/` (whole folder)
   - `ios/AgriPrice/Features/Market/` replacements (overwrite the 003 stub)
   - `ios/AgriPrice/Features/Trend/` replacements (overwrite the 003 stub)
2. Drag `ios/AgriPriceTests/ROCDateFormatterTests.swift`, `MOAClientParsingTests.swift`, `MarketViewModelTests.swift` into the `AgriPriceTests` target.
3. ⌘B to verify the project compiles.

## Smoke test on the simulator

1. ⌘R on iPhone 15 simulator.
2. Tap the **行情** tab.
3. Tap the green product chip → pick `FV4 辣椒 朝天椒` → confirm.
4. Tap the date chip → pick "近 7 日" → confirm.
5. Within ~5 s you should see:
   - A summary card with range high / avg / low.
   - One row per market that traded in the window.
   - Each row shows upper / middle / lower / volume.
6. Tap any market row → TrendView opens with a price line + volume bar chart.
7. **Empty state**: pick a date range that's known to be quiet (e.g. a single Sunday). Expect `查無此日期區間行情`, not a spinner.
8. **Offline state**: turn off the simulator's network (`xcrun simctl status_bar ... data_network none` or Mac's airplane mode). Re-tap query. Expect `網路連線異常,請稍後再試` + the cached previous result still visible.

## Verify the home wiring

1. Star `FV4` in the picker.
2. Tab to **首頁** — the `FV4` chip should now appear under 常用品項.
3. Tap it — you should land on the Market tab pre-selected on `FV4` with the date range from your most recent query.

## What is NOT in this feature

- No vendor login (Vendor tab stays a stub).
- No background refresh of cached prices.
- No multi-product comparison view.
