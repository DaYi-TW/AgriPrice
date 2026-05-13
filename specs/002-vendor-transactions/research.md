# Research: Vendor Transactions

This feature has three non-obvious areas that aren't pinned by the spec or dev spec. The decisions below are the contract `VendorAPIClient`, `KeychainStore`, and `VendorViewModel` implement.

## 1. chill-api envelope quirks

**Observation**: chill-api returns the same JSON envelope shape on every status it owns (200 / 401 / 500 / 502). Only HTTP 422 — FastAPI's request-validation default — uses a different shape (`{"detail":[…]}`).

**Decisions**:

- **Drive UI routing from `success` + `error_code`, never `message`.** The server's `message` is server-localized text that may change wording. The app maps `error_code` → zh-Hant string from dev spec §18 itself; it does not pass `message` through to the UI.
- **`success: true` with `market_data: []` is a *success* path.** It renders the totals (which may be 0) plus the empty-state line `今天無銷售資料`. It is **not** an error and does **not** clear the password field.
- **A 200 with `success: false` is treated as `INTERNAL_ERROR`.** Per the chill-api contract, that shouldn't happen, but if it does we'd rather surface a friendly error than crash the decoder.
- **A non-200 with `success: true` is also treated as `INTERNAL_ERROR`.** Same reason.
- **Decode failure at any HTTP status → `INTERNAL_ERROR`.** The user sees `系統內部錯誤,請聯絡管理員` and the developer sees a redacted log line (`status=<n> decode_failed=true`).

## 2. FastAPI 422 shape

**Observation**: FastAPI's default validation error returns:

```json
{ "detail": [ { "loc": ["body","credentials","supply_no"], "msg": "field required", "type": "value_error.missing" } ] }
```

…with no `success` / `error_code` keys.

**Decisions**:

- **Don't try to parse 422 into the standard envelope.** Catch the decode failure and emit `INTERNAL_ERROR` (FR-005, "422 / malformed response → 系統內部錯誤,請聯絡管理員").
- **422 should be unreachable from the iOS app.** We always send all three fields. If it ever fires in TestFlight, that's a real bug to look at — not a user-visible message to tune.
- **Don't log the `detail` array.** It includes the field `loc` path which can hint at the request shape; redact to just `status=422`.

## 3. Password redaction

The hard constraint from Constitution III + FR-009 is: the password string appears in exactly two places in the running app, and nowhere else.

1. The `SecureField` binding while the user is typing.
2. The `kSecValueData` of the Keychain item (only if 記住密碼 is on).

Specifically forbidden:

- `print(password)` / `NSLog` / `os_log` / any analytics breadcrumb.
- The `URLRequest.httpBody` must never be logged or surfaced in `description`.
- Crash logs must not contain `password=…` — we never put it in any model's `description`.
- The chill-api `VendorScrapeResponse` echo: the server contract says the response never echoes the password. We verify by structure: the response Codable has no `password` field at all, so even if the server regressed and added one, it wouldn't deserialize anywhere.

**Implementation choices**:

- `VendorScrapeRequest` is `fileprivate` to `VendorAPIClient.swift`. Other files cannot construct it or print it.
- `VendorAPIClient` exposes one method: `func scrape(supplyNo:supplySub:password:) async -> APIResult<VendorScrapeData>`. The password parameter is consumed immediately to build the body; the parameter is not stored on `self`.
- All client logging goes through `private func log(method:status:errorCode:)`, which takes only those three values — there is no overload that could accidentally accept the request body.
- `VendorViewModel` keeps the password in a local `let` inside the async task, not on `self`. After the request completes (success or failure), the local goes out of scope.

## 4. Biometry probe (P2)

**`LAContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:)`** returns `false` on:

- Simulator without Face ID enrolled (handled — falls back to manual entry).
- A device whose owner has not enrolled biometry.
- A device whose biometry has been disabled by passcode lockout.

**Decisions**:

- Probe at the moment the user flips 記住密碼 from off to on. If unavailable, snap the toggle back to off and show `此裝置未設定 Face ID / Touch ID` inline (FR-011).
- Probe again on read. If biometry has been disabled since enable-time (e.g. the user disabled Face ID in Settings), surface a friendly inline message and let the user type the password (FR / acceptance §2.4).
- We do not offer a passcode fallback (`.deviceOwnerAuthentication`). The constitution requires biometry specifically; allowing passcode would weaken the access-control guarantee.

## 5. Cancellation semantics

**Decision**: a single optional `Task<Void, Never>` on `VendorViewModel`. On every 查詢 tap:

```swift
inFlight?.cancel()
inFlight = Task { … }
```

The task's body calls `try Task.checkCancellation()` after the await — if cancelled, no state mutation happens. This matches the pattern already used by `MarketViewModel` in feature 001, so reviewers see one cancellation idiom across the app.

## 6. Timeout

**Decision**: 30 s hard timeout via `URLSessionConfiguration.timeoutIntervalForRequest = 30`. Anything beyond that surfaces as `URLError` → `networkError` → `網路連線異常,請稍後再試`. The 10 s budget in SC-001 is a soft target, not a configured cutoff — we don't want to cut off a slow-but-recovering AMIS query at 10 s when the user is already waiting.
