import Foundation

enum ErrorCode: String {
    case networkError = "NETWORK_ERROR"
    case moaParseFailed = "MOA_PARSE_FAILED"
    case invalidDateRange = "INVALID_DATE_RANGE"
    case invalidProductCode = "INVALID_PRODUCT_CODE"
    case unknownError = "UNKNOWN_ERROR"

    var userMessage: String {
        switch self {
        case .networkError:       return "網路連線異常,請稍後再試"
        case .moaParseFailed:     return "資料解析失敗,請稍後再試"
        case .invalidDateRange:   return "開始日期不可晚於結束日期"
        case .invalidProductCode: return "查無此品項"
        case .unknownError:       return "發生未預期錯誤,請稍後再試"
        }
    }
}
