# AgriPrice Development Spec

> 中文名稱：農價通  
> App 類型：iOS Native App  
> 技術棧：SwiftUI / SwiftData / Swift Charts / FastAPI / Cloud Run  
> 版本：MVP Development Spec  
> 更新日期：2026-05-13

---

## 1. 專案概述

AgriPrice 是一個 iOS 農產品行情查詢 App，主要功能包含：

1. 使用 AMIS 官方品項代號查詢所有市場行情
2. 使用日期區間查詢價格與交易量
3. 顯示市場排行與趨勢圖
4. 查詢供應商今日成交金額
5. 使用 iPhone 本機保存查詢紀錄與常用品項

---

## 2. 技術架構

```text
iOS App
  ├─ SwiftUI：畫面開發
  ├─ SwiftData：本機資料保存
  ├─ Swift Charts：趨勢圖
  ├─ Keychain：供應商帳密保存，可選
  └─ URLSession：呼叫後端 API

GCP Cloud Run
  └─ FastAPI
      ├─ AMIS 行情查詢 Proxy
      ├─ 供應商成交查詢 Proxy
      ├─ HTML Parser
      └─ JSON Normalizer

External Source
  └─ AMIS 農產品批發市場交易行情站
```

---

## 3. 專案 Repository

建議拆成兩個 repo：

```text
agriprice-ios
agriprice-api
```

---

# Part A. iOS App Spec

---

## 4. iOS 版本需求

| 項目 | 建議 |
|---|---|
| Minimum iOS | iOS 17 |
| UI Framework | SwiftUI |
| Local DB | SwiftData |
| Chart | Swift Charts |
| Secret Storage | Keychain |
| Network | URLSession async/await |
| Distribution | TestFlight |

---

## 5. App Navigation

Bottom Tab Bar：

```text
Home
Market
Vendor
Trend
```

中文顯示：

```text
首頁
行情
成交
趨勢
```

---

## 6. iOS 畫面清單

### 6.1 HomeView

首頁呈現：

- 今日最關注行情
- 全市場均價
- 今日漲跌幅
- 最高市場
- 最低市場
- 成交摘要
- 主要功能入口
- 常用品項

主要互動：

| 操作 | 結果 |
|---|---|
| 點 Hero 行情卡 | 進入 MarketView |
| 點市場行情 | 進入 MarketView |
| 點今日成交 | 進入 VendorQueryView |
| 點常用品項 | 設定品項後進入 MarketView |

---

### 6.2 MarketView

行情查詢頁。

元件：

- 品項卡片
- 日期區間卡片
- 區間最高 / 均價 / 最低
- 市場行情列表

互動：

| 操作 | 結果 |
|---|---|
| 點品項卡片 | 開啟 ProductPickerSheet |
| 點日期卡片 | 開啟 DateRangeSheet |
| 點市場列 | 進入 TrendView |
| 點收藏星號 | 將品項設為常用 |

---

### 6.3 ProductPickerSheet

品項選擇 Bottom Sheet。

需求：

- 顯示 AMIS 官方品項代號
- 支援常用品項排序
- 星號品項排前面
- 不顯示「較常用」文字 badge
- 點選後關閉 Sheet 並更新目前品項

範例品項：

```text
FV4 辣椒 朝天椒
FV1 辣椒 紅小
FV2 辣椒 青小
FV5 辣椒 青龍
FV6 辣椒 糯米椒
LA1 甘藍 初秋
LA2 甘藍 改良種
SG5 大蒜 蒜頭
SE1 青蔥 日蔥
SD1 洋蔥 本產
```

---

### 6.4 DateRangeSheet

日期區間 Bottom Sheet。

預設：

```text
今天 ～ 今天
```

快捷選項：

- 今天
- 本月
- 近 7 日
- 近 30 日
- 近 90 日

欄位：

```text
startDate
endDate
```

驗證規則：

| 規則 | 說明 |
|---|---|
| startDate 不可大於 endDate | 否則顯示錯誤 |
| endDate 不可大於今天 | 避免查未來日期 |
| 預設為今天 | App 第一次開啟時使用今天～今天 |

---

### 6.5 TrendView

趨勢分析頁。

資料來源：

- 本機 SwiftData 已保存資料
- 或 Cloud Run 即時查詢後存本機

內容：

- 價格折線圖
- 交易量長條圖
- 市場比較
- 區間最高 / 平均 / 最低
- 簡易趨勢摘要

---

### 6.6 VendorQueryView

今日成交查詢頁。

欄位：

```text
supplierCode
subCode
password
```

按鈕：

```text
查詢今天賣多少錢
```

安全要求：

- password 不可用 UserDefaults 儲存
- 若要記住密碼，使用 Keychain
- API request 不記錄密碼

---

### 6.7 VendorResultView

今日成交結果頁。

顯示：

- 今日成交總額
- 總重量
- 平均單價
- 各市場成交列表

市場列表欄位：

```text
marketName
itemCount
totalWeight
averagePrice
totalAmount
```

點市場後進入：

```text
VendorMarketDetailView
```

---

### 6.8 VendorMarketDetailView

各市場成交明細。

顯示：

- 市場成交總額
- 成交件數
- 總重量
- 平均單價
- 各件成交明細

各件欄位：

```text
itemNo
productCode
productName
grade
weight
unitPrice
amount
```

---

## 7. SwiftData Model

### 7.1 ProductItem

```swift
@Model
final class ProductItem {
    var code: String
    var name: String
    var category: String?
    var isFavorite: Bool
    var sortOrder: Int
    var updatedAt: Date

    init(
        code: String,
        name: String,
        category: String? = nil,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        updatedAt: Date = .now
    ) {
        self.code = code
        self.name = name
        self.category = category
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.updatedAt = updatedAt
    }
}
```

---

### 7.2 MarketPriceRecord

```swift
@Model
final class MarketPriceRecord {
    var productCode: String
    var productName: String
    var marketCode: String?
    var marketName: String
    var tradeDate: Date
    var upperPrice: Double?
    var middlePrice: Double?
    var lowerPrice: Double?
    var averagePrice: Double?
    var volume: Double?
    var createdAt: Date

    init(
        productCode: String,
        productName: String,
        marketCode: String? = nil,
        marketName: String,
        tradeDate: Date,
        upperPrice: Double? = nil,
        middlePrice: Double? = nil,
        lowerPrice: Double? = nil,
        averagePrice: Double? = nil,
        volume: Double? = nil,
        createdAt: Date = .now
    ) {
        self.productCode = productCode
        self.productName = productName
        self.marketCode = marketCode
        self.marketName = marketName
        self.tradeDate = tradeDate
        self.upperPrice = upperPrice
        self.middlePrice = middlePrice
        self.lowerPrice = lowerPrice
        self.averagePrice = averagePrice
        self.volume = volume
        self.createdAt = createdAt
    }
}
```

---

### 7.3 RecentQuery

```swift
@Model
final class RecentQuery {
    var productCode: String
    var productName: String
    var startDate: Date
    var endDate: Date
    var queriedAt: Date

    init(
        productCode: String,
        productName: String,
        startDate: Date,
        endDate: Date,
        queriedAt: Date = .now
    ) {
        self.productCode = productCode
        self.productName = productName
        self.startDate = startDate
        self.endDate = endDate
        self.queriedAt = queriedAt
    }
}
```

---

### 7.4 VendorQueryProfile

> 不建議直接存密碼。密碼若要保存，請放 Keychain。

```swift
@Model
final class VendorQueryProfile {
    var supplierCode: String
    var subCode: String
    var rememberCredential: Bool
    var updatedAt: Date

    init(
        supplierCode: String,
        subCode: String,
        rememberCredential: Bool = false,
        updatedAt: Date = .now
    ) {
        self.supplierCode = supplierCode
        self.subCode = subCode
        self.rememberCredential = rememberCredential
        self.updatedAt = updatedAt
    }
}
```

---

# Part B. API Spec

---

## 8. API Base URL

Development：

```text
http://localhost:8000
```

Production：

```text
https://agriprice-api-xxxxx.a.run.app
```

---

## 9. API Response Format

所有 API 統一格式：

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

錯誤格式：

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AMIS_QUERY_FAILED",
    "message": "Failed to query AMIS data."
  }
}
```

---

## 10. Market Price API

### 10.1 查詢指定品項所有市場行情

```http
GET /api/v1/market-prices
```

Query Parameters：

| Name | Type | Required | Description |
|---|---|---|---|
| product_code | string | yes | AMIS 品項代號，例如 FV4 |
| start_date | string | yes | YYYY-MM-DD |
| end_date | string | yes | YYYY-MM-DD |

Example：

```http
GET /api/v1/market-prices?product_code=FV4&start_date=2026-05-13&end_date=2026-05-13
```

Response：

```json
{
  "success": true,
  "data": {
    "product": {
      "code": "FV4",
      "name": "辣椒 朝天椒"
    },
    "date_range": {
      "start_date": "2026-05-13",
      "end_date": "2026-05-13"
    },
    "summary": {
      "highest_price": 95.0,
      "lowest_price": 62.0,
      "average_price": 82.0,
      "total_volume": 15680.0
    },
    "markets": [
      {
        "market_code": "104",
        "market_name": "台北一市",
        "upper_price": 95.0,
        "middle_price": 82.0,
        "lower_price": 70.0,
        "average_price": 82.0,
        "volume": 1250.0,
        "change_rate": 17.1
      }
    ]
  },
  "error": null
}
```

---

## 11. Trend API

### 11.1 查詢趨勢資料

```http
GET /api/v1/market-prices/trend
```

Query Parameters：

| Name | Type | Required | Description |
|---|---|---|---|
| product_code | string | yes | AMIS 品項代號 |
| market_code | string | no | 市場代號，不給則回傳全市場平均 |
| start_date | string | yes | YYYY-MM-DD |
| end_date | string | yes | YYYY-MM-DD |

Response：

```json
{
  "success": true,
  "data": {
    "product": {
      "code": "FV4",
      "name": "辣椒 朝天椒"
    },
    "market": {
      "code": "104",
      "name": "台北一市"
    },
    "points": [
      {
        "date": "2026-05-13",
        "average_price": 82.0,
        "volume": 1250.0
      }
    ]
  },
  "error": null
}
```

---

## 12. Product API

### 12.1 取得品項代號表

```http
GET /api/v1/products
```

Response：

```json
{
  "success": true,
  "data": [
    {
      "code": "FV4",
      "name": "辣椒 朝天椒",
      "category": "辣椒"
    }
  ],
  "error": null
}
```

備註：

第一版可將品項代號表直接內建於 iOS App，API 可延後實作。

---

## 13. Vendor Transaction API

### 13.1 查詢供應商今日成交

```http
POST /api/v1/vendor/transactions
```

Request：

```json
{
  "supplier_code": "A12345",
  "sub_code": "001",
  "password": "********",
  "trade_date": "2026-05-13"
}
```

Response：

```json
{
  "success": true,
  "data": {
    "trade_date": "2026-05-13",
    "summary": {
      "total_amount": 12860,
      "total_weight": 168,
      "average_price": 76.5
    },
    "markets": [
      {
        "market_code": "104",
        "market_name": "台北一市",
        "item_count": 3,
        "total_weight": 88,
        "average_price": 82.0,
        "total_amount": 7216,
        "items": [
          {
            "item_no": "001",
            "product_code": "FV4",
            "product_name": "朝天椒",
            "grade": "A",
            "weight": 30,
            "unit_price": 85,
            "amount": 2550
          }
        ]
      }
    ]
  },
  "error": null
}
```

安全要求：

- API 不記錄 password
- Log middleware 必須遮蔽 password
- 不將供應商密碼保存至任何後端資料庫

---

# Part C. Backend Spec

---

## 14. FastAPI 專案結構

```text
agriprice-api/
├── app/
│   ├── main.py
│   ├── api/
│   │   ├── market_prices.py
│   │   ├── products.py
│   │   └── vendor.py
│   ├── services/
│   │   ├── amis_client.py
│   │   ├── market_price_parser.py
│   │   └── vendor_parser.py
│   ├── schemas/
│   │   ├── common.py
│   │   ├── market_price.py
│   │   ├── product.py
│   │   └── vendor.py
│   └── core/
│       ├── config.py
│       └── logging.py
├── Dockerfile
├── requirements.txt
└── README.md
```

---

## 15. Backend Dependencies

```txt
fastapi
uvicorn[standard]
httpx
beautifulsoup4
lxml
pydantic
python-dotenv
```

---

## 16. Cloud Run Deployment

Dockerfile：

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

Deploy：

```bash
gcloud run deploy agriprice-api \
  --source . \
  --region asia-east1 \
  --allow-unauthenticated
```

---

# Part D. Error Handling

---

## 17. Error Codes

| Code | Description |
|---|---|
| INVALID_PRODUCT_CODE | 品項代號不存在 |
| INVALID_DATE_RANGE | 日期區間錯誤 |
| AMIS_QUERY_FAILED | AMIS 查詢失敗 |
| AMIS_PARSE_FAILED | AMIS 回傳格式解析失敗 |
| VENDOR_AUTH_FAILED | 供應商登入失敗 |
| VENDOR_QUERY_FAILED | 供應商成交查詢失敗 |
| NETWORK_ERROR | 網路錯誤 |
| UNKNOWN_ERROR | 未知錯誤 |

---

## 18. iOS 錯誤提示

| 情境 | error_code | 顯示文字 |
|---|---|---|
| 網路失敗 / timeout | `NETWORK_ERROR` (iOS-only) | 網路連線異常,請稍後再試 |
| MOA 回傳 `Data: []` | — | 查無此日期區間行情 |
| MOA `RS != "OK"` | `INVALID_PRODUCT_CODE` | 查無此品項 |
| MOA JSON 解析失敗 | `MOA_PARSE_FAILED` | 資料解析失敗,請稍後再試 |
| 日期錯誤 | `INVALID_DATE_RANGE` | 開始日期不可晚於結束日期 |
| chill-api 401(密碼錯) | `AUTH_FAILED` | 登入失敗,請確認供應商號碼/密碼 |
| chill-api 502(AMIS 異常) | `UPSTREAM_ERROR` | 資料來源網站暫時無法存取,請稍後再試 |
| chill-api 500 / 422 / 解析失敗 | `INTERNAL_ERROR` | 系統內部錯誤,請聯絡管理員 |
| vendor 今日無銷售 | (success, market_data=[]) | 今天無銷售資料 |
| 未啟用生物辨識卻開啟「記住密碼」 | — | 此裝置未設定 Face ID / Touch ID |
| 未預期錯誤 | `UNKNOWN_ERROR` | 發生未預期錯誤,請稍後再試 |

字串以 iOS 程式碼裡 `ErrorCode.userMessage`（`ios/AgriPrice/Common/ErrorCode.swift`）為準。
新增字串必須先進這張表,再回頭改程式碼。

---

# Part E. Security

---

## 19. Credential Handling

供應商密碼處理規則：

```text
禁止存 UserDefaults
禁止存 SwiftData
禁止寫入 Log
禁止送到第三方服務
```

允許：

```text
iOS Keychain
```

---

## 20. Logging Policy

後端 Log 不可出現：

```text
password
supplier_code + password combination
raw vendor response containing sensitive information
```

建議遮蔽：

```json
{
  "supplier_code": "A12***",
  "sub_code": "001",
  "password": "***"
}
```

---

# Part F. MVP Acceptance Criteria

---

## 21. Functional Acceptance Criteria

### 行情查詢

- 使用者可以選 FV4 查詢今天～今天行情
- 使用者可以更改日期區間
- 使用者可以查看所有市場列表
- 使用者可以查看最高、平均、最低價格
- 使用者可以點市場進入趨勢頁

### 品項選擇

- 使用者可以點綠色品項卡開啟選單
- 使用者可以切換品項
- 使用者可以星號收藏品項
- 收藏品項排序在前面

### 成交查詢

- 使用者可以輸入供應商代號、小代號、密碼
- 使用者可以查看今日成交總額
- 使用者可以查看各市場成交
- 使用者可以點市場查看各件明細

### 趨勢分析

- 使用者可以查看價格折線圖
- 使用者可以查看交易量長條圖
- 日期區間與行情頁同步

---

## 22. Non-functional Acceptance Criteria

| 項目 | 標準 |
|---|---|
| App 啟動 | 2 秒內進入首頁 |
| 查詢 API | 5 秒內回傳 |
| 無資料狀態 | 顯示友善提示 |
| 密碼保存 | 僅可使用 Keychain |
| GCP 成本 | 不使用 Cloud SQL / Firestore |
| 使用者數 | 以少量親友使用為前提 |

---

## 23. Future Enhancements

- iCloud 同步收藏品項
- 推播價格提醒
- 匯出 CSV
- 更完整的 AMIS 品項代號資料管理
- 多市場自訂比較
- App Store 非公開上架
- 後端資料庫版本
- 每日定時抓取行情
- AI 價格異常摘要

---

## 24. MVP 結論

AgriPrice 第一版應採用：

```text
SwiftUI
+ SwiftData
+ Swift Charts
+ Keychain
+ FastAPI Cloud Run
+ AMIS Proxy
```

不使用 GCP 資料庫，以降低成本並簡化維運。
