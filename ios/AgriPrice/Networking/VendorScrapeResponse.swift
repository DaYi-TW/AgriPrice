import Foundation

/// Envelope returned by chill-api for every status it owns (200 / 401 / 500 / 502).
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

struct VendorScrapeData: Decodable, Equatable {
    let todayTotalProfit: Double
    let yearTotal: Double
    let marketData: [VendorMarketRow]

    enum CodingKeys: String, CodingKey {
        case todayTotalProfit = "today_total_profit"
        case yearTotal = "year_total"
        case marketData = "market_data"
    }
}

struct VendorMarketRow: Decodable, Equatable, Identifiable {
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
