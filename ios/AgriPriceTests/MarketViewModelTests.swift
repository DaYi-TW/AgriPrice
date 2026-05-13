import XCTest
import SwiftData
@testable import AgriPrice

@MainActor
final class MarketViewModelTests: XCTestCase {

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

    func test_loaded_success_writes_records_and_recent_query() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let product = ProductItem(code: "FV4", name: "辣椒 朝天椒")
        context.insert(product)

        let row = MarketPriceRecord(
            productCode: "FV4",
            productName: "辣椒 朝天椒",
            marketCode: "104",
            marketName: "台北一",
            tradeDate: .now,
            upperPrice: 100,
            averagePrice: 90,
            volume: 500
        )
        let stub = StubMOAClient(result: .success([row]))

        let vm = MarketViewModel(client: stub)
        vm.setSelection(product: product)
        vm.reload(into: context)

        try await Task.sleep(nanoseconds: 200_000_000)

        if case .loaded(let rows) = vm.state {
            XCTAssertEqual(rows.count, 1)
        } else {
            XCTFail("expected loaded, got \(vm.state)")
        }

        let recents = try context.fetch(FetchDescriptor<RecentQuery>())
        XCTAssertEqual(recents.count, 1)
        XCTAssertEqual(recents.first?.productCode, "FV4")
    }

    func test_empty_data_yields_empty_state_and_no_recent_query() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let product = ProductItem(code: "FV4", name: "辣椒 朝天椒")
        context.insert(product)

        let stub = StubMOAClient(result: .success([]))
        let vm = MarketViewModel(client: stub)
        vm.setSelection(product: product)
        vm.reload(into: context)
        try await Task.sleep(nanoseconds: 200_000_000)

        if case .empty = vm.state { /* ok */ }
        else { XCTFail("expected empty, got \(vm.state)") }

        let recents = try context.fetch(FetchDescriptor<RecentQuery>())
        XCTAssertTrue(recents.isEmpty)
    }

    func test_failure_yields_error_state() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let product = ProductItem(code: "FV4", name: "辣椒 朝天椒")
        context.insert(product)

        let stub = StubMOAClient(result: .failure(code: .networkError, message: ErrorCode.networkError.userMessage))
        let vm = MarketViewModel(client: stub)
        vm.setSelection(product: product)
        vm.reload(into: context)
        try await Task.sleep(nanoseconds: 200_000_000)

        if case .error(let message) = vm.state {
            XCTAssertEqual(message, "網路連線異常,請稍後再試")
        } else {
            XCTFail("expected error, got \(vm.state)")
        }
    }
}

private final class StubMOAClient: MOAClientProtocol {
    let result: APIResult<[MarketPriceRecord]>
    init(result: APIResult<[MarketPriceRecord]>) { self.result = result }
    func fetchPrices(productCode: String, startDate: Date, endDate: Date) async -> APIResult<[MarketPriceRecord]> {
        result
    }
}
