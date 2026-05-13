# Research: Market Price Query

## MOA AgriProductsTransType endpoint

```
GET https://data.moa.gov.tw/api/v1/AgriProductsTransType/
    ?Start_time=107.07.01
    &End_time=107.07.10
    &CropCode=FV4
```

### Verified response (live, 2026-05-13)

```json
{
  "RS": "OK",
  "Data": [
    {
      "TransDate": "107.07.02",
      "CropCode": "FV4",
      "CropName": "辣椒-朝天椒",
      "MarketCode": "104",
      "MarketName": "台北一",
      "Upper_Price": 146.7,
      "Middle_Price": 120,
      "Lower_Price": 100,
      "Avg_Price": 121.7,
      "Trans_Quantity": 2080
    }
  ]
}
```

### Quirks the iOS layer must absorb

| Quirk | What we do |
|---|---|
| Dates are ROC `YYY.MM.DD` with dots | `ROCDateFormatter` converts both directions. UI never sees ROC. |
| `CropCode` is case-sensitive | Bundled list stores codes capitalized (`FV4`); never lowercase before sending. |
| `CropName` uses a hyphen (`辣椒-朝天椒`) | We display our own bundled name (with a space), not MOA's. |
| `RS = "OK"` with empty `Data: []` | Friendly empty state (`查無此日期區間行情`), not an error. |
| `RS = "ERROR"` | Map to `INVALID_PRODUCT_CODE` or `UNKNOWN_ERROR` depending on context. |
| `Trans_Quantity` is in kg (公斤) | Display as-is; the mockup already labels the column 「成交量(公斤)」. |
| HTTP 200 with malformed JSON | Map to `MOA_PARSE_FAILED`. |
| Network failure (no DNS, no route) | Map to `NETWORK_ERROR`; show cached `MarketPriceRecord` if any. |

### Why not a proxy?

The endpoint is public, free, served over HTTPS, and accepts no API key. A proxy would add a Cloud Run cold start, a second deploy target, and a service we can't run locally. The only reasons to add one later are (a) MOA introduces a secret-bearing auth scheme, or (b) we need a per-user rate limiter — neither applies in v1. See Constitution Principle II.

### ROC ↔ ISO conversion

Use `Calendar(identifier: .republicOfChina)` for both directions; do not hand-roll `year - 1911`. The ROC calendar in Foundation handles the 1911 epoch, leap years, and zero-padding via `DateFormatter` with `"y.MM.dd"`.

Reference: `Calendar.Identifier.republicOfChina` is available since iOS 4; safe on iOS 17.
