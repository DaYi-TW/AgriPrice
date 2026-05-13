import XCTest
@testable import AgriPrice

final class VendorAPIClientParsingTests: XCTestCase {

    private let client = VendorAPIClient()

    func test_200_success_decodes_payload() {
        let json = """
        {
          "success": true,
          "message": "數據獲取成功",
          "timestamp": "2026-05-13T13:54:49.495366",
          "data": {
            "today_total_profit": 777,
            "year_total": 333666,
            "market_data": [
              {"market":"台北一","product_name":"辣椒-朝天椒","average_price":121.7,"quantity":2080}
            ]
          },
          "error_code": null
        }
        """.data(using: .utf8)!

        let result = client.decode(status: 200, data: json)
        guard case .success(let payload) = result else { return XCTFail("expected success, got \(result)") }
        XCTAssertEqual(payload.todayTotalProfit, 777)
        XCTAssertEqual(payload.yearTotal, 333666)
        XCTAssertEqual(payload.marketData.count, 1)
        XCTAssertEqual(payload.marketData.first?.market, "台北一")
        XCTAssertEqual(payload.marketData.first?.averagePrice, 121.7)
    }

    func test_200_empty_market_data_is_success_with_empty_list() {
        let json = """
        {
          "success": true,
          "message": "今天無銷售資料",
          "data": {"today_total_profit": 0, "year_total": 333000, "market_data": []},
          "error_code": null
        }
        """.data(using: .utf8)!

        let result = client.decode(status: 200, data: json)
        guard case .success(let payload) = result else { return XCTFail("expected success") }
        XCTAssertTrue(payload.marketData.isEmpty)
        XCTAssertEqual(payload.yearTotal, 333000)
    }

    func test_401_auth_failed_maps_to_authFailed() {
        let json = """
        {"success": false, "message": "登入失敗", "data": null, "error_code": "AUTH_FAILED"}
        """.data(using: .utf8)!

        let result = client.decode(status: 401, data: json)
        guard case .failure(let code, let message) = result else { return XCTFail("expected failure") }
        XCTAssertEqual(code, .authFailed)
        XCTAssertEqual(message, "登入失敗,請確認供應商號碼/密碼")
    }

    func test_502_upstream_error_maps_to_upstreamError() {
        let json = """
        {"success": false, "data": null, "error_code": "UPSTREAM_ERROR"}
        """.data(using: .utf8)!

        let result = client.decode(status: 502, data: json)
        guard case .failure(let code, let message) = result else { return XCTFail("expected failure") }
        XCTAssertEqual(code, .upstreamError)
        XCTAssertEqual(message, "資料來源網站暫時無法存取,請稍後再試")
    }

    func test_500_internal_error_maps_to_internalError() {
        let json = """
        {"success": false, "data": null, "error_code": "INTERNAL_ERROR"}
        """.data(using: .utf8)!

        let result = client.decode(status: 500, data: json)
        guard case .failure(let code, _) = result else { return XCTFail("expected failure") }
        XCTAssertEqual(code, .internalError)
    }

    func test_422_fastapi_default_maps_to_internalError() {
        let json = """
        {"detail":[{"loc":["body","credentials","supply_no"],"msg":"field required","type":"value_error.missing"}]}
        """.data(using: .utf8)!

        let result = client.decode(status: 422, data: json)
        guard case .failure(let code, _) = result else { return XCTFail("expected failure") }
        XCTAssertEqual(code, .internalError)
    }

    func test_malformed_json_at_200_maps_to_internalError() {
        let data = Data("not json".utf8)
        let result = client.decode(status: 200, data: data)
        guard case .failure(let code, _) = result else { return XCTFail("expected failure") }
        XCTAssertEqual(code, .internalError)
    }

    func test_200_with_success_false_maps_to_internalError() {
        let json = """
        {"success": false, "data": null, "error_code": null}
        """.data(using: .utf8)!

        let result = client.decode(status: 200, data: json)
        guard case .failure(let code, _) = result else { return XCTFail("expected failure") }
        XCTAssertEqual(code, .internalError)
    }
}
