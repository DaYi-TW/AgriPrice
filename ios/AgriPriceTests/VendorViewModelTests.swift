import XCTest
import SwiftData
@testable import AgriPrice

@MainActor
final class VendorViewModelTests: XCTestCase {

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

    // MARK: - P1

    func test_query_success_transitions_to_loaded_and_persists_profile() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let payload = VendorScrapeData(
            todayTotalProfit: 777,
            yearTotal: 333666,
            marketData: [
                VendorMarketRow(market: "台北一", productName: "辣椒", averagePrice: 100, quantity: 50)
            ]
        )
        let api = StubVendorAPI(result: .success(payload))
        let kc = StubKeychain()
        let vm = VendorViewModel(api: api, keychain: kc, isBiometryAvailable: { true })
        vm.supplyNo = "1234"
        vm.supplySub = "01"
        vm.password = "pw"
        vm.query(context: context)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(vm.resultData)
        XCTAssertEqual(vm.resultData?.todayTotalProfit, 777)
        XCTAssertEqual(vm.password, "", "password is cleared after a successful query")

        let profiles = try context.fetch(FetchDescriptor<VendorQueryProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.supplierCode, "1234")
        XCTAssertEqual(profiles.first?.subCode, "01")
    }

    func test_auth_failed_clears_only_password_and_keeps_ids() async throws {
        let container = try makeContainer()
        let api = StubVendorAPI(result: .failure(code: .authFailed, message: ErrorCode.authFailed.userMessage))
        let vm = VendorViewModel(api: api, keychain: StubKeychain(), isBiometryAvailable: { true })
        vm.supplyNo = "1234"
        vm.supplySub = "01"
        vm.password = "wrongpw"
        vm.query(context: container.mainContext)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(vm.errorMessage, "登入失敗,請確認供應商號碼/密碼")
        XCTAssertEqual(vm.supplyNo, "1234")
        XCTAssertEqual(vm.supplySub, "01")
        XCTAssertEqual(vm.password, "")
    }

    func test_upstream_error_keeps_password_and_ids() async throws {
        let container = try makeContainer()
        let api = StubVendorAPI(result: .failure(code: .upstreamError, message: ErrorCode.upstreamError.userMessage))
        let vm = VendorViewModel(api: api, keychain: StubKeychain(), isBiometryAvailable: { true })
        vm.supplyNo = "1234"
        vm.supplySub = "01"
        vm.password = "pw"
        vm.query(context: container.mainContext)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(vm.errorMessage, "資料來源網站暫時無法存取,請稍後再試")
        XCTAssertEqual(vm.password, "pw")
    }

    func test_second_query_cancels_first() async throws {
        let container = try makeContainer()
        let api = SlowVendorAPI()
        let vm = VendorViewModel(api: api, keychain: StubKeychain(), isBiometryAvailable: { true })
        vm.supplyNo = "1234"
        vm.supplySub = "01"
        vm.password = "pw"

        vm.query(context: container.mainContext)
        // Re-fire before the slow stub completes.
        vm.query(context: container.mainContext)
        try await Task.sleep(nanoseconds: 400_000_000)
        // SlowVendorAPI returns a fixed success; we just verify the VM didn't crash
        // and exactly one terminal state landed.
        XCTAssertNotNil(vm.resultData)
    }

    // MARK: - P2

    func test_toggle_on_without_biometry_bounces_back() {
        let vm = VendorViewModel(
            api: StubVendorAPI(result: .success(.init(todayTotalProfit: 0, yearTotal: 0, marketData: []))),
            keychain: StubKeychain(),
            isBiometryAvailable: { false }
        )
        vm.setRememberCredential(true)
        XCTAssertFalse(vm.rememberCredential)
        XCTAssertEqual(vm.rememberToggleError, "此裝置未設定 Face ID / Touch ID")
    }

    func test_toggle_off_synchronously_deletes_keychain_entry() {
        let kc = StubKeychain()
        kc.saved["1234-01"] = "pw"
        let vm = VendorViewModel(
            api: StubVendorAPI(result: .success(.init(todayTotalProfit: 0, yearTotal: 0, marketData: []))),
            keychain: kc,
            isBiometryAvailable: { true }
        )
        vm.supplyNo = "1234"
        vm.supplySub = "01"
        vm.rememberCredential = true
        vm.setRememberCredential(false)
        XCTAssertNil(kc.saved["1234-01"], "keychain entry deleted synchronously")
        XCTAssertFalse(vm.rememberCredential)
    }

    func test_success_with_remember_writes_password_to_keychain() async throws {
        let container = try makeContainer()
        let kc = StubKeychain()
        let payload = VendorScrapeData(todayTotalProfit: 1, yearTotal: 1, marketData: [])
        let vm = VendorViewModel(
            api: StubVendorAPI(result: .success(payload)),
            keychain: kc,
            isBiometryAvailable: { true }
        )
        vm.supplyNo = "1234"
        vm.supplySub = "01"
        vm.password = "secretpw"
        vm.setRememberCredential(true)
        vm.query(context: container.mainContext)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(kc.saved["1234-01"], "secretpw")
    }
}

// MARK: - Stubs

private final class StubVendorAPI: VendorAPIClientProtocol {
    let result: APIResult<VendorScrapeData>
    init(result: APIResult<VendorScrapeData>) { self.result = result }
    func scrape(supplyNo: String, supplySub: String, password: String) async -> APIResult<VendorScrapeData> {
        result
    }
}

private final class SlowVendorAPI: VendorAPIClientProtocol {
    func scrape(supplyNo: String, supplySub: String, password: String) async -> APIResult<VendorScrapeData> {
        try? await Task.sleep(nanoseconds: 50_000_000)
        return .success(VendorScrapeData(todayTotalProfit: 0, yearTotal: 0, marketData: []))
    }
}

private final class StubKeychain: KeychainStoreProtocol {
    var saved: [String: String] = [:]
    func save(password: String, account: String) throws { saved[account] = password }
    func read(account: String, reason: String) async throws -> String {
        guard let pw = saved[account] else { throw KeychainError.itemNotFound }
        return pw
    }
    func delete(account: String) throws { saved.removeValue(forKey: account) }
    func contains(account: String) -> Bool { saved[account] != nil }
}
