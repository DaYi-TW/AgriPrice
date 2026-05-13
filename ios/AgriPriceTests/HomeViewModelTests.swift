import XCTest
import SwiftData
@testable import AgriPrice

final class HomeViewModelTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ProductItem.self,
                MarketPriceRecord.self,
                RecentQuery.self,
                VendorQueryProfile.self,
            configurations: config
        )
    }

    func testFavoriteSort_byOrderThenName() throws {
        let a = ProductItem(code: "A", name: "Alpha",   isFavorite: true, sortOrder: 1)
        let b = ProductItem(code: "B", name: "Bravo",   isFavorite: true, sortOrder: 0)
        let c = ProductItem(code: "C", name: "Charlie", isFavorite: true, sortOrder: 1)

        let sorted = [a, b, c].sorted(by: HomeViewModel.favoriteSort)
        XCTAssertEqual(sorted.map(\.code), ["B", "A", "C"])
    }

    func testTopRecent_returnsMostRecentFirstAndRespectsLimit() {
        let now = Date()
        let queries = (0..<15).map { i in
            RecentQuery(
                productCode: "P\(i)",
                productName: "Product \(i)",
                startDate: now,
                endDate: now,
                queriedAt: now.addingTimeInterval(TimeInterval(i))
            )
        }
        let top = HomeViewModel.topRecent(queries, limit: 10)
        XCTAssertEqual(top.count, 10)
        XCTAssertEqual(top.first?.productCode, "P14")
        XCTAssertEqual(top.last?.productCode, "P5")
    }
}
