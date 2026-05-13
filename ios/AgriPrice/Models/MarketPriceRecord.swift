import Foundation
import SwiftData

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
