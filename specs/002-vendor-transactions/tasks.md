# Tasks: Vendor Transactions

**Branch**: `002-vendor-transactions`
**Inputs**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md) · [quickstart.md](./quickstart.md)

Order: foundation → P1 (MVP) → P2 → P3 → polish. Each task is small enough to land in one focused commit.

## Foundation — shared infrastructure

- **T001**  Extend `ios/AgriPrice/Common/ErrorCode.swift`: add `.authFailed`, `.upstreamError`, `.internalError`, `.networkError` (if not already present) with the zh-Hant `userMessage` values from data-model.md.
- **T002**  Write `ios/AgriPrice/Common/KeychainStore.swift`. Methods: `save(password:account:) throws`, `read(account:reason:) async throws -> String`, `delete(account:) throws`. The save path builds `SecAccessControl` with `.biometryCurrentSet` + `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. The read path attaches a fresh `LAContext` via `kSecUseAuthenticationContext`.
- **T003**  Write `ios/AgriPrice/Common/BiometryAvailability.swift`. Single function: `static func isAvailable() -> Bool` wrapping `LAContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:)`.
- **T004**  Write `ios/AgriPrice/Networking/VendorScrapeResponse.swift`. Exactly the Codables from data-model.md (`VendorScrapeResponse`, `VendorScrapeData`, `VendorMarketRow`).
- **T005**  Write `ios/AgriPrice/Networking/VendorAPIClient.swift`. Define `protocol VendorAPIClientProtocol` with `func scrape(supplyNo:supplySub:password:) async -> APIResult<VendorScrapeData>`. Live implementation `VendorAPIClient: VendorAPIClientProtocol` posts to `https://chill-api-240848983153.asia-east1.run.app/api/scrape`, decodes the envelope, maps HTTP status + `error_code` per data-model.md, and emits exactly one redacted log line per attempt.

## P1 — Today's transactions for a logged-in supplier (MVP)

- **T100**  Write `ios/AgriPriceTests/VendorAPIClientParsingTests.swift`. Cases: 200 success, 200 empty `market_data`, 401 `AUTH_FAILED`, 502 `UPSTREAM_ERROR`, 500 `INTERNAL_ERROR`, 422 FastAPI shape, malformed JSON at 200, URLError. Uses a `URLProtocol`-stub session. **Authored before T101.**
- **T101**  Write `ios/AgriPrice/Features/Vendor/VendorViewModel.swift`. `@Observable @MainActor` with state `VendorViewState`, fields `supplyNo`, `supplySub`, `password`, `rememberCredential`, `errorMessage`. Method `query(context:)` cancels any prior task, fires the API client, persists `VendorQueryProfile` on success, clears only `password` on `AUTH_FAILED`.
- **T102**  Write `ios/AgriPriceTests/VendorViewModelTests.swift` against a stub `VendorAPIClientProtocol`. Cases: success transitions to `.loaded`; AUTH_FAILED clears password only; multi-call cancels prior task; UPSTREAM/INTERNAL/network messages match §18.
- **T103**  Write `ios/AgriPrice/Features/Vendor/VendorLoginForm.swift`. Three `TextField` / `SecureField` rows, the 記住密碼 toggle, the 查詢 button, inline error label bound to `viewModel.errorMessage`.
- **T104**  Write `ios/AgriPrice/Features/Vendor/VendorResultsView.swift`. Two cards (今日總利潤 / 本年累計) and a `List` of `VendorMarketRow`. Empty-state row `今天無銷售資料` when `marketData` is empty.
- **T105**  Replace `ios/AgriPrice/Features/Vendor/VendorView.swift` (currently the 003 stub). Switches on `viewModel.state` to show the login form or the results view; preserves `viewModel` across renders via `@State`.

## P2 — Remember credentials with biometry

- **T200**  In `VendorViewModel`, wire the 記住密碼 toggle:
  - On flip ON: probe `BiometryAvailability.isAvailable()`. If false, snap toggle back, surface `此裝置未設定 Face ID / Touch ID`.
  - On flip OFF: synchronously `try KeychainStore.delete(account:)` before `rememberCredential = false` writes back.
- **T201**  In `VendorViewModel`, when `rememberCredential` is on and `password.isEmpty`, attempt `KeychainStore.read(account:reason: "解鎖以讀取供應商密碼")` before posting. On read failure (denied / unavailable), keep the form editable — do not block the user.
- **T202**  After a successful query with `rememberCredential` on, save the password to Keychain (overwrite any prior entry under the same account).
- **T203**  Add a P2 case to `VendorViewModelTests.swift` using a stub `KeychainStoreProtocol`: toggle-off triggers `delete` synchronously; toggle-on with no biometry triggers the inline message.

## P3 — Recent supplier on Home

- **T300**  In `ios/AgriPrice/Features/Home/HomeView.swift`, append a footer card after the existing 最近查詢 section. Show only when a `VendorQueryProfile` row exists; render `上次查詢成交: <supplyNo>-<supplySub> (HH:mm)` using `updatedAt`.
- **T301**  Wire the tap action to switch the `AppShell` selected tab to 成交 (use the binding already exposed from 003 shell).

## Polish

- **T900**  Add the four new zh-Hant strings to dev spec §18 (`登入失敗,請確認供應商號碼/密碼`, `資料來源網站暫時無法存取,請稍後再試`, `系統內部錯誤,請聯絡管理員`, `今天無銷售資料`) so future features inherit them.
- **T901**  Update `README.md`: change the **成交** tab row from `⏸️ stub` to `✅ shipped (002)`; add a one-line note that chill-api is the upstream.
- **T902**  Manual on-device smoke per `quickstart.md` P1 + P2 + P3 + the debug-log audit (SC-003).
- **T903**  Commit + merge to `main` + push.

## Dependencies

```
T001 ─┐
T002 ─┼─► (P1 starts at T100)
T003 ─┤
T004 ─┤
T005 ─┘
T100 ──► T101 ──► T102
                  └─► T103, T104 ──► T105
T105 ──► T200, T201, T202 ──► T203
T105 ──► T300 ──► T301
all ──► T900–T903
```

## Independent test coverage

- **P1 MVP**: T100 + T102 cover the network → state-machine path with no UI; T105 covers the wiring; quickstart §P1 covers the UI.
- **P2**: T203 + quickstart §P2 cover the Keychain + biometry path independently of any chill-api change.
- **P3**: quickstart §P3 covers the Home wiring independently of P2 (P3 needs only that P1 has run once).
