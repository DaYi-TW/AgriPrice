import Foundation
import SwiftData

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
