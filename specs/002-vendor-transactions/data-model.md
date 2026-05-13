# Data Model: Vendor Transactions

## SwiftData (already declared in 003 shell)

### `VendorQueryProfile` — dev spec §7.4

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | `@Attribute(.unique)`; one row per device in v1 |
| `supplyNo` | `String` | 供應代號 |
| `supplySub` | `String` | 小代號 |
| `rememberCredential` | `Bool` | mirrors the 記住密碼 toggle |
| `updatedAt` | `Date` | set on every successful query (used by Home footer) |

**Never** holds the password. There is at most one row in v1; if more than one is found at read time, treat it as a bug and overwrite on next write.

## iOS Keychain item

| Attribute | Value |
|---|---|
| `kSecClass` | `kSecClassGenericPassword` |
| `kSecAttrService` | `"agriprice.vendor.password"` |
| `kSecAttrAccount` | `"\(supplyNo)-\(supplySub)"` |
| `kSecValueData` | UTF-8 bytes of the password |
| `kSecAttrAccessControl` | `SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryCurrentSet, nil)` |
| `kSecUseAuthenticationContext` | a per-read `LAContext` |

Read path: `SecItemCopyMatching` with the access control above triggers the system biometric prompt. `LAContext.localizedReason = "解鎖以讀取供應商密碼"`.

Delete path: `SecItemDelete` is synchronous; the toggle-off handler awaits it before any further request fires.

## chill-api request

```http
POST https://chill-api-240848983153.asia-east1.run.app/api/scrape
Content-Type: application/json
```

```json
{
  "credentials": {
    "supply_no": "...",
    "supply_sub": "...",
    "password": "..."
  }
}
```

```swift
// fileprivate to VendorAPIClient — never escapes the file.
fileprivate struct VendorScrapeRequest: Encodable {
    let credentials: Credentials
    struct Credentials: Encodable {
        let supplyNo: String
        let supplySub: String
        let password: String
        enum CodingKeys: String, CodingKey {
            case supplyNo = "supply_no"
            case supplySub = "supply_sub"
            case password
        }
    }
}
```

Intentional choice: `VendorScrapeRequest` does **not** conform to `CustomStringConvertible` and does **not** get logged anywhere. The `VendorAPIClient` logs only `(method, status, errorCode)` via a private helper.

## chill-api response

Same envelope on success and on each error HTTP status (200 / 401 / 500 / 502):

```json
{
  "success": true,
  "message": "數據獲取成功",
  "timestamp": "2026-05-13T13:54:49.495366",
  "data": {
    "today_total_profit": 777,
    "year_total": 333666,
    "market_data": [
      {
        "market": "台北一",
        "product_name": "辣椒-朝天椒",
        "average_price": 121.7,
        "quantity": 2080
      }
    ]
  },
  "error_code": null
}
```

```swift
struct VendorScrapeResponse: Decodable {
    let success: Bool
    let message: String?
    let timestamp: String?
    let data: VendorScrapeData?
    let errorCode: String?
    enum CodingKeys: String, CodingKey {
        case success, message, timestamp, data
        case errorCode = "error_code"
    }
}

struct VendorScrapeData: Decodable {
    let todayTotalProfit: Double
    let yearTotal: Double
    let marketData: [VendorMarketRow]
    enum CodingKeys: String, CodingKey {
        case todayTotalProfit = "today_total_profit"
        case yearTotal = "year_total"
        case marketData = "market_data"
    }
}

struct VendorMarketRow: Decodable, Identifiable {
    var id: String { "\(market)-\(productName)" }
    let market: String
    let productName: String
    let averagePrice: Double
    let quantity: Double
    enum CodingKeys: String, CodingKey {
        case market
        case productName = "product_name"
        case averagePrice = "average_price"
        case quantity
    }
}
```

## Error mapping

| HTTP | `error_code`     | App outcome |
|------|------------------|-------------|
| 200  | `null`           | `success(VendorScrapeData)` — UI renders totals + rows (or empty state if `market_data: []`) |
| 401  | `AUTH_FAILED`    | `failure(.authFailed, "登入失敗,請確認供應商號碼/密碼")` — clear password field, keep IDs |
| 502  | `UPSTREAM_ERROR` | `failure(.upstreamError, "資料來源網站暫時無法存取,請稍後再試")` |
| 500  | `INTERNAL_ERROR` | `failure(.internalError, "系統內部錯誤,請聯絡管理員")` |
| 422  | (FastAPI raw)    | `failure(.internalError, "系統內部錯誤,請聯絡管理員")` — should be unreachable from iOS |
| —    | `URLError`       | `failure(.networkError, "網路連線異常,請稍後再試")` |
| any  | decode failure   | `failure(.internalError, "系統內部錯誤,請聯絡管理員")` |

```swift
enum VendorErrorCode: String {
    case authFailed = "AUTH_FAILED"
    case upstreamError = "UPSTREAM_ERROR"
    case internalError = "INTERNAL_ERROR"
    case networkError                   // iOS-only sentinel
}
```

`ErrorCode` (the global enum) gets three new cases mirroring the strings above; `VendorErrorCode` maps to it 1:1.

## View model state

```swift
enum VendorViewState {
    case loggedOut                              // show login form
    case loading                                // 查詢 in flight
    case loaded(VendorScrapeData)               // results visible
    case failure(message: String)               // inline error on login form
}
```

A separate `clearPasswordOnFailure: Bool` flag is read once after `.failure` to decide whether to clear the password field (true for `.authFailed`, false for everything else).
