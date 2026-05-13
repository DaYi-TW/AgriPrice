import Foundation
import SwiftData

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
