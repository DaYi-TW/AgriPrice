# Data Model: iOS App Shell

Source: dev spec §7. Copied verbatim into `ios/AgriPrice/Models/`. No schema changes.

## ProductItem (§7.1)

| Field | Type | Notes |
|---|---|---|
| `code` | `String` | AMIS / MOA `CropCode`. Primary identity for UI. |
| `name` | `String` | zh-Hant display name, e.g. "辣椒 朝天椒". |
| `category` | `String?` | Optional grouping for picker UI. |
| `isFavorite` | `Bool` | True → sort to top of picker. |
| `sortOrder` | `Int` | Tie-breaker among favorites; lower wins. |
| `updatedAt` | `Date` | Set on every mutation. |

## MarketPriceRecord (§7.2)

One (product, market, tradeDate) tuple. Used by 001 to cache MOA results.

| Field | Type |
|---|---|
| `productCode` | `String` |
| `productName` | `String` |
| `marketCode` | `String?` |
| `marketName` | `String` |
| `tradeDate` | `Date` |
| `upperPrice` | `Double?` |
| `middlePrice` | `Double?` |
| `lowerPrice` | `Double?` |
| `averagePrice` | `Double?` |
| `volume` | `Double?` |
| `createdAt` | `Date` |

## RecentQuery (§7.3)

| Field | Type |
|---|---|
| `productCode` | `String` |
| `productName` | `String` |
| `startDate` | `Date` |
| `endDate` | `Date` |
| `queriedAt` | `Date` |

## VendorQueryProfile (§7.4)

Per-device identity of the supplier. **Never** contains password — password lives in Keychain only (constitution III).

| Field | Type |
|---|---|
| `supplierCode` | `String` |
| `subCode` | `String` |
| `rememberCredential` | `Bool` |
| `updatedAt` | `Date` |

## Seed data: BundledProducts.json

First-launch seed for `ProductItem`. v1 crops from dev spec §6.3:

```json
[
  { "code": "FV4", "name": "辣椒 朝天椒", "category": "辣椒" },
  { "code": "FV1", "name": "辣椒 紅小",   "category": "辣椒" },
  { "code": "FV2", "name": "辣椒 青小",   "category": "辣椒" },
  { "code": "FV5", "name": "辣椒 青龍",   "category": "辣椒" },
  { "code": "FV6", "name": "辣椒 糯米椒", "category": "辣椒" },
  { "code": "LA1", "name": "甘藍 初秋",   "category": "甘藍" },
  { "code": "LA2", "name": "甘藍 改良種", "category": "甘藍" },
  { "code": "SG5", "name": "大蒜 蒜頭",   "category": "大蒜" },
  { "code": "SE1", "name": "青蔥 日蔥",   "category": "青蔥" },
  { "code": "SD1", "name": "洋蔥 本產",   "category": "洋蔥" }
]
```
