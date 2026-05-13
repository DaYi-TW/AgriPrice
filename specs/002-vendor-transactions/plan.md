# Implementation Plan: Vendor Transactions

**Branch**: `002-vendor-transactions` | **Date**: 2026-05-13 | **Spec**: [./spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-vendor-transactions/spec.md`

## Summary

Add the **成交** tab: a SwiftUI login form (供應代號 / 小代號 / 密碼) that POSTs to the externally-maintained `chill-api` Cloud Run service and renders today's transactions across markets, plus 今日總利潤 and 本年累計. Opt-in **記住密碼** stores the password in iOS Keychain behind `SecAccessControl` (`.biometryCurrentSet` + `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`); 供應代號 + 小代號 persist in SwiftData (`VendorQueryProfile`). On the Home tab, a small "上次查詢成交" footer card appears after the first successful query.

No backend code lands in this repo — chill-api is treated as an external upstream, exactly like MOA in feature 001.

## Technical Context

**Language/Version**: Swift 5.9 (iOS 17.0 SDK)
**Primary Dependencies**: SwiftUI, SwiftData, URLSession, Security (Keychain), LocalAuthentication (`LAContext`).
**Storage**:
- SwiftData `VendorQueryProfile` (dev spec §7.4): `supplyNo`, `supplySub`, `rememberCredential`, `updatedAt`.
- iOS Keychain item, account = `"\(supplyNo)-\(supplySub)"`, service = `"agriprice.vendor.password"`, biometry-gated.
**Testing**: XCTest. Unit tests for `VendorAPIClient` response parsing (success / empty / each error_code / 422 / URLError) and `VendorViewModel` state transitions with a stubbed client. Keychain + biometry are integration concerns and are smoke-tested on device per quickstart.md.
**Target Platform**: iOS 17.0+, iPhone only, light mode locked (already enforced by 003 shell).
**Project Type**: iOS app — extends the existing `ios/AgriPrice/` tree.
**Performance Goals**:
- SC-001: cold start → first results with 記住密碼 on ≤ 12 s (2 s launch + 10 s budget for chill-api).
- Hard request timeout: 30 s.
**Constraints**:
- Constitution III: password lives only in Keychain. **No logging of request body or password under any conditions.**
- zh-Hant strings only in shipped UI.
- No third-party Keychain libs (Constitution V).
**Scale/Scope**: ≤ 80 TestFlight users; one supplier identity per device.

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. On-Device First | PASS | The only persistence we add is SwiftData (`VendorQueryProfile`, no password) + Keychain (password, biometry-gated). No server-side user data. |
| II. No Backend Code in This Repo | PASS | iOS calls `chill-api` directly. The service is maintained in a separate repo and consumed as an external dependency, exactly as Principle II (v2.1.0) describes. No `api/` directory added. |
| III. Keychain-Only Credentials | PASS | Password storage uses `SecAccessControl` with `.biometryCurrentSet` + `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Reads require `LAContext` biometric prompt. Toggling 記住密碼 off deletes the Keychain entry synchronously before any other action. FR-009 forbids logging the password or the request body — enforced by routing all chill-api logging through a redacting helper. |
| IV. Spec-Driven Development | PASS | spec.md is in place; this plan + tasks.md gate implementation. |
| V. iOS 17 + SwiftUI + SwiftData + Swift Charts + URLSession | PASS | All Apple-native. No third-party libs. `LocalAuthentication` and `Security` are system frameworks. |
| VI. Friendly Error States Over Raw Errors | PASS | Every chill-api outcome maps to a zh-Hant string from dev spec §18. New entries (`登入失敗,請確認供應商號碼/密碼`, `資料來源網站暫時無法存取,請稍後再試`, `系統內部錯誤,請聯絡管理員`, `今天無銷售資料`) will be added to §18 before code merges. |
| VII. Simplicity Over Features | PASS | Today-only query, no date picker. One vendor identity per device. No multi-account UI. |

**Gate**: PASS. No complexity tracking needed.

## Project Structure

### Documentation

```text
specs/002-vendor-transactions/
├── spec.md              # already written
├── plan.md              # this file
├── data-model.md        # VendorScrapeResponse / VendorMarketRow Codables + Keychain layout
├── research.md          # chill-api quirks, 422 FastAPI shape, password redaction strategy
├── quickstart.md        # how to test login + biometry on a device
└── tasks.md             # produced by /speckit-tasks
```

### Source Code (new and modified files)

```text
ios/
├── AgriPrice/
│   ├── Common/
│   │   ├── ErrorCode.swift               # MODIFY: add AUTH_FAILED / UPSTREAM_ERROR / INTERNAL_ERROR cases + zh-Hant userMessage
│   │   ├── KeychainStore.swift           # NEW: thin wrapper around Security framework with SecAccessControl + LAContext read
│   │   └── BiometryAvailability.swift    # NEW: LAContext.canEvaluatePolicy probe used by the toggle
│   ├── Networking/
│   │   ├── VendorScrapeResponse.swift    # NEW: Codable for chill-api envelope + nested data
│   │   └── VendorAPIClient.swift         # NEW: protocol + URLSession impl, redacted logging
│   ├── Features/
│   │   ├── Vendor/
│   │   │   ├── VendorView.swift          # REPLACE stub: composes login or results based on state
│   │   │   ├── VendorViewModel.swift     # NEW: @Observable @MainActor; owns Task cancellation, Keychain reads, SwiftData writes
│   │   │   ├── VendorLoginForm.swift     # NEW: three fields + 記住密碼 toggle + 查詢 button + inline error
│   │   │   └── VendorResultsView.swift   # NEW: 今日總利潤 card, 本年累計 card, market rows
│   │   └── Home/
│   │       └── HomeView.swift            # MODIFY: append "上次查詢成交" footer card when VendorQueryProfile.updatedAt is set
└── AgriPriceTests/
    ├── VendorAPIClientParsingTests.swift # NEW: success / empty / each error_code / 422 / decode failure
    └── VendorViewModelTests.swift        # NEW: state transitions with a stub client; Keychain stubbed via protocol
```

**Structure Decision**: This feature only adds files under `ios/AgriPrice/{Common,Networking,Features/Vendor}` and `ios/AgriPriceTests/`. No new top-level directory.

## Phase 0: Research

`research.md` will capture three things that aren't obvious from the spec alone:

1. **chill-api envelope quirks** — `success: true` with `market_data: []` is the documented empty state; the iOS app must not treat it as an error. The `message` field is server-localized zh-Hant and we ignore it for routing decisions (we drive UI from `success` + `error_code` only).
2. **FastAPI 422 shape** — when the request body fails validation, FastAPI returns `{"detail":[{"loc":[...],"msg":"...","type":"..."}]}` with no `success` / `error_code` field. iOS treats any decode failure on 422 as `INTERNAL_ERROR`.
3. **Password redaction** — the chill-api URLRequest must never be logged via `print`, `os_log`, `URLSession.shared.delegate` traces, or `URLProtocol`. Logging in `VendorAPIClient` only ever uses pre-redacted metadata (HTTP method + status + decoded `error_code`). The Codable for the request body is kept private to the client so it cannot accidentally leak via `CustomStringConvertible`.

## Phase 1: Design

### data-model.md

Will contain:
- The exact `VendorScrapeResponse` Codable matching the chill-api envelope.
- `VendorScrapeData` with `today_total_profit`, `year_total`, `market_data`.
- `VendorMarketRow` with `market`, `product_name`, `average_price`, `quantity`.
- `VendorErrorCode` enum: `.authFailed`, `.upstreamError`, `.internalError`, `.networkError` (iOS-only).
- The Keychain layout: service, account format, `SecAccessControl` flags, `kSecUseAuthenticationContext` with our `LAContext`.
- A note that `VendorQueryProfile` (dev spec §7.4 / already in 003 shell) is the SwiftData side.

### quickstart.md

Will document the on-device test plan:
- Run on a physical iPhone with Face ID enrolled.
- Steps 1–5 for P1 (login form → success → empty state → wrong password → offline).
- Steps 6–9 for P2 (toggle 記住密碼 → kill → relaunch → Face ID prompt → result).
- Steps 10–11 for P3 (return to Home → footer card → tap-to-jump).

### Constitution re-check after design

No violations. `KeychainStore` is the only Security-framework caller and is the only owner of the access-control flags; the rest of the app never sees the password as a `String`.

## Cross-cutting decisions

- **No DI container.** Views receive their view model via `@State` init; view models receive `VendorAPIClient` and `KeychainStore` protocols via init defaults (live in production, stubs in tests).
- **Single in-flight request.** `VendorViewModel` holds an optional `Task<Void, Never>`; on a second tap of 查詢, it cancels the prior task before launching a new one (FR-012).
- **No logging of the request body.** `VendorAPIClient` logs only `method=POST status=<int> error_code=<code|nil>` via a private redacting helper. The Codable for the request body is `fileprivate` to the client file.
- **Keychain delete is synchronous.** The toggle handler awaits Keychain delete before any further user action can fire — `rememberCredential = false` flips after `KeychainStore.delete()` returns. FR-008 + SC-004.
- **Biometry probe before showing the toggle as on.** When the user flips 記住密碼 on, we run `LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:)`. If unavailable, the toggle springs back to off with the inline message (FR-011).
- **No iCloud Keychain sharing.** The access control is `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — credentials never leave the device.
- **Home footer card** is a small view in `HomeView` driven by `@Query` over `VendorQueryProfile` filtered to the single existing row; tap navigates by switching the `AppShell` selected tab via an `@Environment`-injected binding (already present from 003).

## Risks

1. **AMIS markup change breaks chill-api** → users get `UPSTREAM_ERROR`. We can't fix it from iOS; the chill-api maintainer must redeploy. Mitigation: copy in the error string already points users to "稍後再試"; we don't promise a fix window.
2. **User declines biometry mid-session** → password field becomes editable for manual entry (FR / acceptance §2.4). No retry loop on biometry — one prompt per query.
3. **Keychain entry survives app uninstall** by default. iOS purges Keychain entries with `...ThisDeviceOnly` access on uninstall only on iOS 11+, which we satisfy. No further action needed.
4. **No Xcode build on this dev machine.** Same as 001 — Swift sources are written but type-checked by inspection; the macOS contributor verifies. Mitigation: keep `VendorAPIClient` + `KeychainStore` behind small protocols so the test target alone (when running on macOS) covers the parsing and state-machine logic without needing a device.
