# Data Model: Market Price Query

## Upstream: MOA `AgriProductsTransType`

### Request (built by `MOAClient`)

| Param | Type | Example | Source |
|---|---|---|---|
| `Start_time` | ROC `YYY.MM.DD` | `107.07.01` | `ROCDateFormatter.string(from:startDate)` |
| `End_time` | ROC `YYY.MM.DD` | `107.07.10` | `ROCDateFormatter.string(from:endDate)` |
| `CropCode` | String | `FV4` | `ProductItem.code`, capitalized as-stored |

### Response DTO (Codable, internal to `Networking/`)

```swift
struct MOAResponse: Decodable {
    let RS: String
    let Data: [MOARow]?
}

struct MOARow: Decodable {
    let TransDate: String       // ROC "YYY.MM.DD"
    let CropCode: String
    let CropName: String
    let MarketCode: String?
    let MarketName: String
    let Upper_Price: Double?
    let Middle_Price: Double?
    let Lower_Price: Double?
    let Avg_Price: Double?
    let Trans_Quantity: Double?
}
```

`MOAResponse` and `MOARow` are **not** exposed outside `Networking/`. The client maps them to `MarketPriceRecord` (dev spec §7.2) before returning.

## Internal: `MarketPriceRecord` (already defined in 003)

| Field | Source |
|---|---|
| `productCode` | `MOARow.CropCode` |
| `productName` | Looked up from local `ProductItem` by code (we use our display name, not MOA's) |
| `marketCode` | `MOARow.MarketCode` |
| `marketName` | `MOARow.MarketName` |
| `tradeDate` | `ROCDateFormatter.date(from: TransDate)` |
| `upperPrice` | `MOARow.Upper_Price` |
| `middlePrice` | `MOARow.Middle_Price` |
| `lowerPrice` | `MOARow.Lower_Price` |
| `averagePrice` | `MOARow.Avg_Price` |
| `volume` | `MOARow.Trans_Quantity` |
| `createdAt` | `Date()` at insert |

## ErrorCode (`ios/AgriPrice/Common/ErrorCode.swift`)

Mirrors dev spec §17.

| Case | When | User-visible message (§18) |
|---|---|---|
| `.networkError` | `URLError` (offline, DNS, timeout) | `網路連線異常,請稍後再試` |
| `.moaParseFailed` | JSON decode failure or `RS != "OK"` with non-empty `RS` | `資料解析失敗,請稍後再試` |
| `.invalidDateRange` | start > end OR end > today (caught client-side before the request) | `開始日期不可晚於結束日期` / `結束日期不可晚於今日` |
| `.invalidProductCode` | `RS = "ERROR"` AND the request looked otherwise valid | `查無此品項` |
| `.unknownError` | everything else | `發生未預期錯誤,請稍後再試` |

Empty `Data: []` is **not** an error — it's a `success(empty)` result the view maps to the friendly empty state `查無此日期區間行情`.

## APIResult

```swift
enum APIResult<T> {
    case success(T)
    case failure(code: ErrorCode, message: String)
}
```

`MOAClient.fetchPrices(...)` returns `APIResult<[MarketPriceRecord]>`. The view model never sees an exception thrown from the network layer.

## RecentQuery write-through

Every **successful** `MOAClient.fetchPrices(productCode, startDate, endDate)` call appends a `RecentQuery` row with `queriedAt = Date()`. Failures don't write. The Home tab's recent-query list (003) picks these up automatically via its `@Query`.
