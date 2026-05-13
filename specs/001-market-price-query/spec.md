# Feature Specification: Market Price Query

**Feature Branch**: `001-market-price-query`
**Created**: 2026-05-13
**Status**: Draft
**Input**: User description: "Query market prices across all AMIS markets by product code and date range"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Today's prices across all markets (Priority: P1)

A vegetable supplier opens AgriPrice in the morning, picks `FV4 辣椒 朝天椒` from the product picker, and immediately sees today's upper/middle/lower price and traded volume for every wholesale market that traded that crop today, plus the range high/low/average across markets.

**Why this priority**: This is the single most-used query for the family/friends user base — "what did my crop go for today, everywhere?". Without it the app has no reason to exist.

**Independent Test**: Open the iOS Market tab on a network-connected simulator, pick a product, and confirm the screen renders one row per market plus the summary card. (The MOA upstream is live and free; no test harness needed.) Delivers value even if Trend (Story 2) and favorites (Story 3) are absent.

**Acceptance Scenarios**:

1. **Given** the app cold-starts on the Home tab, **When** the user taps the green product card and chooses `FV4`, **Then** the Market view shows today's date range, a summary card with range high/avg/low, and one row per market with upper/middle/lower/volume.
2. **Given** the user is on the Market view with `FV4` selected today, **When** the MOA upstream returns no rows for today (e.g. market closed, weekend), **Then** the screen shows the friendly empty-state "查無此日期區間行情" instead of a stuck spinner or raw error.
3. **Given** the device has no network, **When** the user triggers the query, **Then** an inline error "網路連線異常,請稍後再試" is shown and the previously cached result (if any) remains visible.

---

### User Story 2 - Date range and trend drill-down (Priority: P2)

After seeing today's prices, the user wants to know whether today's number is unusually high or low. They tap the date card, pick "近 7 日", then tap a market row to drill into a trend view that shows price line + volume bars for that market over the range.

**Why this priority**: Trend context turns a single number into a decision. Less critical than P1 because the P1 number is still meaningful on its own, but heavily requested.

**Independent Test**: With Story 1 working, change the date range via the bottom sheet preset chips ("今天", "近 7 日", "近 30 日", "近 90 日") and confirm the summary and market list update. Tapping a market row opens TrendView and renders a line chart with at least the date points returned.

**Acceptance Scenarios**:

1. **Given** the Market view is showing today's data, **When** the user opens the date sheet, picks "近 7 日", and confirms, **Then** the summary recomputes over the 7-day window and the per-market rows show the 7-day high/avg/low for that market.
2. **Given** the user has selected a 7-day range, **When** they tap the "台北一市" row, **Then** TrendView opens with a price line chart and volume bar chart over the same 7-day range for `FV4 @ 台北一市`.
3. **Given** the user picks a `startDate` after `endDate`, **When** they confirm the sheet, **Then** the sheet shows an inline error "開始日期不可晚於結束日期" and does not close.
4. **Given** the user picks an `endDate` after today, **When** they confirm, **Then** the sheet rejects the input.

---

### User Story 3 - Favorite products jump to the top (Priority: P3)

A user who tracks the same 3–5 crops every day stars them once; from then on those products appear at the top of the product picker, and the Home screen surfaces a "常用品項" shortcut grid that opens the Market view pre-filtered to that crop with the user's last date range.

**Why this priority**: A convenience layer over P1. The product list works without it; favorites just make repeat use fast.

**Independent Test**: Star a product in the picker sheet, close and reopen the app, and confirm (a) the starred product appears first in the picker and (b) a shortcut chip for it appears on the Home screen.

**Acceptance Scenarios**:

1. **Given** the product picker is open, **When** the user taps the star on `FV4`, **Then** `FV4` moves to the top of the list and the star is filled.
2. **Given** the user has 3 favorites, **When** they kill and relaunch the app, **Then** the same 3 favorites are still favorited and still ordered at the top.
3. **Given** the user has favorites, **When** they tap a Home shortcut for `FV4`, **Then** Market view opens with `FV4` selected and the date range from the user's most recent query (or today–today on first run).

---

### Edge Cases

- **MOA returns ROC-formatted dates** in the response (e.g. `107.07.01`) — the Swift `MOAClient` is responsible for ISO ↔ ROC conversion in both directions. UI / SwiftData layers only ever see `Date` / ISO strings.
- **Crop has no transactions on a chosen date** (weekend/holiday/off-season) — show empty state per Story 1 #2, not an error.
- **Some markets traded, others didn't** — render only the markets that returned rows; the summary high/avg/low is over those markets only.
- **Date range spans a market closure window** — gaps in trend chart are rendered as broken lines, not zero-imputed.
- **User switches product while a previous request is in flight** — cancel the prior request; only the latest selection's data is rendered.
- **MOA upstream is slow (> 5 s)** — show a skeleton state; if exceeding the §22 NFR (5 s), show a non-blocking warning but keep waiting up to a hard cap (15 s) before erroring out.
- **Cached SwiftData result exists but is stale** — show cached value immediately, then refresh in background; mark with a subtle "更新中" indicator.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST let the user pick a product by AMIS product code (e.g. `FV4`) from a bottom-sheet picker that lists code + Chinese name.
- **FR-002**: System MUST let the user pick a date range with both custom start/end dates and the preset chips: 今天, 本月, 近 7 日, 近 30 日, 近 90 日.
- **FR-003**: System MUST default the date range to today–today on first launch.
- **FR-004**: System MUST reject `startDate > endDate` and `endDate > today` at the date sheet, with the inline error strings from dev spec §18.
- **FR-005**: System MUST display, for the selected product+range: range high price, range average price, range low price, and one row per market with upper/middle/lower/average price and volume.
- **FR-006**: System MUST allow drill-down from a market row into a trend view with a price line chart and a volume bar chart over the same date range.
- **FR-007**: System MUST let the user star/unstar any product; starred products MUST sort to the top of the picker and persist across app launches.
- **FR-008**: System MUST cache successful query results in SwiftData (`MarketPriceRecord`) so the most recent result is visible offline.
- **FR-009**: System MUST surface the user's recent queries (last N, where N ≥ 5) so they can be re-run with one tap.
- **FR-010**: iOS `MOAClient` MUST convert ISO `YYYY-MM-DD` to ROC `YYY.MM.DD` (year = Gregorian − 1911, zero-padded month/day, dots as separators) when building the request URL, using `CropCode` as the upstream parameter name.
- **FR-011**: iOS `MOAClient` MUST decode the MOA `{RS, Data}` response into Swift values and normalize each row to ISO `Date` + the internal `MarketPriceRecord` shape from dev spec §7.2.
- **FR-012**: iOS networking layer MUST map any failure into a typed `ErrorCode` (`NETWORK_ERROR`, `MOA_PARSE_FAILED`, `INVALID_DATE_RANGE`, `INVALID_PRODUCT_CODE`, `UNKNOWN_ERROR`) and surface only the dev-spec §18 zh-Hant message to the user — never the underlying `URLError`, status code, or JSON decode error.

### Key Entities

- **Product**: AMIS-defined crop, identified by `CropCode` (mapped to internal `code`). Has Chinese name, optional category. Bundled in the iOS app for v1.
- **Market**: One wholesale market (台北一市, 板橋, 台中, 高雄, …). Identified by market code in the MOA response.
- **MarketPriceRecord**: One (product, market, tradeDate) tuple with upper/middle/lower/average price and volume. Persisted in SwiftData per dev spec §7.2.
- **RecentQuery**: One (productCode, startDate, endDate, queriedAt) tuple per dev spec §7.3.
- **DateRange**: A (startDate, endDate) pair with the validation rules in FR-004.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From cold start, the user can see today's prices for their last-used product in **under 3 seconds** on a TestFlight build over LTE (dev spec NFR: 2 s app launch + 5 s API budget — this metric tightens by leveraging cached results).
- **SC-002**: A user who has favorited their top 3 products reaches the Market view for any of them in **≤ 2 taps from Home** (Home shortcut → Market).
- **SC-003**: When the MOA upstream returns an empty result set, **100% of the time** the screen shows the friendly empty-state message — never a spinner, a crash, or a raw error code.
- **SC-004**: Trend drill-down renders the chart within **2 seconds** when the data is already cached locally for the chosen range.
- **SC-005**: Over a 30-day pilot with the family/friends cohort, fewer than **5% of queries** result in a user-visible error (network error excluded).

## Assumptions

- The MOA open-data endpoint `https://data.moa.gov.tw/api/v1/AgriProductsTransType/` is stable and free (no API key required) for the AgriPrice usage volume. If MOA introduces rate limits or auth, the iOS app ships an update with a new auth header or — if a secret cannot live in the binary — Constitution II must be revisited.
- The v1 product code list is **bundled into the iOS app** (dev spec §12.1 note). There is no remote product catalog to fetch.
- Users have iOS 17+ (required for SwiftData).
- "Trend" in Story 2 reuses the same MOA endpoint with a wider date range — there is no separate trend data source. The trend view aggregates the same response, grouped by trade date.
- The user is on LTE or Wi-Fi; offline-first design is limited to "show the last successful query from SwiftData cache"; we do not pre-fetch background data.
- The bundled product list covers the user's day-1 crops (辣椒 / 甘藍 / 大蒜 / 青蔥 / 洋蔥 + extensions); adding a new crop is a v1.1 concern.
- App Transport Security default settings are sufficient — `data.moa.gov.tw` serves valid HTTPS with TLS 1.2+.
