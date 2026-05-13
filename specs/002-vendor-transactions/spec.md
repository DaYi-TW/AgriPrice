# Feature Specification: Vendor Transactions

**Feature Branch**: `002-vendor-transactions`
**Created**: 2026-05-13
**Status**: Draft
**Input**: User description: "Supplier logs in with 供應代號 + 小代號 + 密碼 and sees today's transactions across markets, plus total profit and year-to-date total."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Today's transactions for a logged-in supplier (Priority: P1) — MVP

A supplier opens the **成交** tab, enters 供應代號 + 小代號 + 密碼, taps 查詢, and within ~10 s sees three things:

1. **今日總利潤** (single number, NTD).
2. **本年累計** (single number, NTD).
3. **各市場成交** (one row per market: market name, product name, average price, quantity).

**Why this priority**: It's the entire feature. Without P1 the 成交 tab has nothing.

**Independent Test**: With real chill-api credentials, open the 成交 tab, enter creds, tap 查詢. Expect the three sections to render. The empty-state for "today no transactions" must show the friendly message `今天無銷售資料`, not an error.

**Acceptance Scenarios**:

1. **Given** the user has never logged in, **When** they open 成交, **Then** the screen shows a login form with three labeled fields (供應代號 / 小代號 / 密碼) and a 查詢 button. The 密碼 field is masked.
2. **Given** the user enters valid credentials and taps 查詢, **When** the chill-api returns `{success: true, data: {…}}`, **Then** the screen swaps to the results layout: 今日總利潤 card, 本年累計 card, then a list of market rows.
3. **Given** the response is `{success: true, message: "今天無銷售資料", data: {…, market_data: []}}`, **Then** the screen shows the same two profit cards (with whatever totals came back) and an empty-state message under them: `今天無銷售資料`.
4. **Given** the credentials are wrong, **When** the chill-api returns HTTP 401 with `error_code: "AUTH_FAILED"`, **Then** the form stays visible with the inline error `登入失敗,請確認供應商號碼/密碼`, the 密碼 field is cleared, and 供應代號 + 小代號 remain filled.
5. **Given** the chill-api returns 502 / 500 (`UPSTREAM_ERROR` / `INTERNAL_ERROR`), **Then** the form shows the message from `error_code` mapped via dev spec §18 (`資料來源網站暫時無法存取,請稍後再試` or `系統內部錯誤,請聯絡管理員`), creds preserved.
6. **Given** the device has no network, **When** the user taps 查詢, **Then** an inline `網路連線異常,請稍後再試` shows; creds preserved.

---

### User Story 2 - Remember credentials with biometry (Priority: P2)

The user toggles **記住密碼** before tapping 查詢. On the next launch they only need to tap 查詢 — the password is silently fetched from Keychain after a Face ID / Touch ID prompt. Toggling 記住密碼 off deletes the Keychain entry immediately.

**Why this priority**: A supplier checks this daily; re-typing a password every time is a UX wart, but the feature works without it.

**Independent Test**: After P1 works, toggle 記住密碼 on, tap 查詢 successfully, kill the app, reopen → 供應代號 + 小代號 pre-filled, 密碼 blank, tap 查詢 → Face ID prompt → query runs.

**Acceptance Scenarios**:

1. **Given** 記住密碼 is on and the query succeeded, **When** the user kills and relaunches the app, **Then** the form pre-fills 供應代號 + 小代號 from SwiftData and 密碼 from Keychain (after biometric unlock).
2. **Given** 記住密碼 is on, **When** the user toggles it off, **Then** the Keychain entry is deleted before the next request can fire (no async race).
3. **Given** the device has no enrolled biometry, **When** the user toggles 記住密碼 on, **Then** the toggle bounces back with the inline message `此裝置未設定 Face ID / Touch ID`.
4. **Given** the user denies the biometric prompt, **When** they retry 查詢, **Then** the password field becomes editable so they can type it manually (no Keychain read forced).

---

### User Story 3 - Recent supplier on Home (Priority: P3)

The Home tab's existing "最近查詢" list **does not** include vendor queries (it's only for market price queries). But the Home tab gets a small "上次查詢成交" footer card showing the last-queried supplier code and the timestamp, tap-to-jump to the 成交 tab.

**Why this priority**: Pure convenience.

**Independent Test**: After P1, return to Home. A small card at the bottom of Home reads `上次查詢成交: 供應代號-小代號 (HH:mm)`. Tap → 成交 tab opens with creds pre-filled.

**Acceptance Scenarios**:

1. **Given** the user just queried successfully in 成交, **When** they switch to Home, **Then** the footer card shows the supplier identity and the query timestamp.
2. **Given** the user has never queried 成交, **When** they're on Home, **Then** the footer card is absent (not an empty placeholder).

---

### Edge Cases

- **Password is wrong but supplier code is right** — AMIS returns an alert; chill-api maps it to HTTP 401 + `AUTH_FAILED`. UI must clear only 密碼, never 供應代號 or 小代號.
- **AMIS adds CAPTCHA / 2FA** — chill-api returns `UPSTREAM_ERROR`. UI shows `資料來源網站暫時無法存取,請稍後再試` and the user is told (in copy) to try the website.
- **chill-api itself is down** — `URLError` → friendly `網路連線異常,請稍後再試`. No crash, no raw HTTP status.
- **Request body validation (422)** — should be unreachable from the iOS app (we always send a complete body); if it happens, treat as `INTERNAL_ERROR` for UI purposes.
- **Slow upstream (> 10 s)** — show skeleton; hard timeout at 30 s with friendly error.
- **Multi-tap on 查詢** — second tap cancels the prior request before firing.
- **Mid-query app backgrounding** — request continues; if it completes while backgrounded, the result is rendered on return.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present a login form on the 成交 tab with three labeled fields: 供應代號 / 小代號 / 密碼. 密碼 MUST be masked (SecureField).
- **FR-002**: System MUST POST to `https://chill-api-240848983153.asia-east1.run.app/api/scrape` with body `{"credentials": {"supply_no", "supply_sub", "password"}}` when the user taps 查詢.
- **FR-003**: System MUST render `today_total_profit`, `year_total`, and a row per `market_data` entry on `success: true` with non-empty `market_data`.
- **FR-004**: System MUST render the two totals and the empty-state message `今天無銷售資料` when `success: true` and `market_data: []`.
- **FR-005**: System MUST map `error_code` values to zh-Hant strings from dev spec §18:
  - `AUTH_FAILED` → `登入失敗,請確認供應商號碼/密碼`
  - `UPSTREAM_ERROR` → `資料來源網站暫時無法存取,請稍後再試`
  - `INTERNAL_ERROR` → `系統內部錯誤,請聯絡管理員`
  - `URLError` (offline / timeout) → `網路連線異常,請稍後再試`
  - 422 / malformed response → `系統內部錯誤,請聯絡管理員`
- **FR-006**: System MUST persist 供應代號 + 小代號 in SwiftData (`VendorQueryProfile`) on every successful login.
- **FR-007**: System MUST store password in iOS Keychain only when 記住密碼 is on. Keychain entry MUST use `SecAccessControl` with `.biometryCurrentSet` flag and `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- **FR-008**: System MUST delete the Keychain password entry immediately when the user toggles 記住密碼 off, before any further request.
- **FR-009**: System MUST NOT log, print, or persist the password anywhere other than the Keychain. The chill-api request body MUST NOT appear in any log line.
- **FR-010**: System MUST present a Face ID / Touch ID prompt before retrieving the stored password from Keychain on subsequent launches.
- **FR-011**: System MUST gracefully handle a device with no enrolled biometry by refusing to enable 記住密碼 (inline message; toggle bounces back to off).
- **FR-012**: System MUST cancel any in-flight chill-api request when the user taps 查詢 a second time before the first response arrives.

### Key Entities

- **VendorQueryProfile** (dev spec §7.4, already in SwiftData): persists 供應代號 / 小代號 / `rememberCredential` flag / `updatedAt`. **Never** holds the password.
- **VendorScrapeResponse**: the chill-api envelope (`success`, `message`, `timestamp`, `data`, `error_code`).
- **VendorMarketRow**: one entry in `data.market_data` (`market`, `product_name`, `average_price`, `quantity`).
- **VendorErrorCode**: enum mirroring `AUTH_FAILED` / `UPSTREAM_ERROR` / `INTERNAL_ERROR` plus iOS-only `networkError`.

## Success Criteria *(mandatory)*

- **SC-001**: From cold start, a returning user with 記住密碼 on can see today's results in **≤ 12 seconds** (≤ 2 s app launch + 10 s upstream budget). Cold-start without 記住密碼 is dominated by typing time and not measured.
- **SC-002**: 100 % of `AUTH_FAILED` responses surface as the friendly zh-Hant message — never as a raw HTTP code, never as a generic "登入失敗" without the hint.
- **SC-003**: 0 occurrences of the password string in console, system, or crash logs across the TestFlight pilot. (Verified by `os_log` filter audit before TF submission.)
- **SC-004**: Toggling 記住密碼 off, then opening the Keychain inspector (or re-launching the app), shows **no** password entry within 1 second of the toggle change.

## Assumptions

- The chill-api service stays at the current URL for the TestFlight pilot. If it moves, this app ships an update.
- A single Cloud Run instance handles our TestFlight load (≤ 80 users, ≤ a few queries per day each).
- The chill-api owner monitors AMIS markup changes; we get a friendly `UPSTREAM_ERROR` rather than corrupt data.
- iOS 17 `LAContext` + `SecAccessControl` is sufficient. We don't need to support fallback PIN entry; if biometry isn't available, the user types the password.
- One supplier identity per device. We don't support multiple vendor accounts on the same device.
