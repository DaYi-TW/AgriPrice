import XCTest
@testable import AgriPrice

final class MOAClientParsingTests: XCTestCase {

    private var client: MOAClient!

    override func setUp() {
        super.setUp()
        client = MOAClient()
    }

    func test_happy_path_decodes_rows() {
        let json = """
        {
          "RS": "OK",
          "Data": [
            {
              "TransDate": "107.07.02",
              "CropCode": "FV4",
              "CropName": "辣椒-朝天椒",
              "MarketCode": "104",
              "MarketName": "台北一",
              "Upper_Price": 146.7,
              "Middle_Price": 120,
              "Lower_Price": 100,
              "Avg_Price": 121.7,
              "Trans_Quantity": 2080
            }
          ]
        }
        """.data(using: .utf8)!

        switch client.decode(data: json, requestedProductCode: "FV4") {
        case .success(let rows):
            XCTAssertEqual(rows.count, 1)
            XCTAssertEqual(rows[0].productCode, "FV4")
            XCTAssertEqual(rows[0].marketName, "台北一")
            XCTAssertEqual(rows[0].averagePrice, 121.7)
            XCTAssertEqual(rows[0].volume, 2080)
        case .failure(let code, _):
            XCTFail("expected success, got \(code)")
        }
    }

    func test_empty_data_is_success_empty_not_error() {
        let json = #"{"RS":"OK","Data":[]}"#.data(using: .utf8)!
        switch client.decode(data: json, requestedProductCode: "FV4") {
        case .success(let rows): XCTAssertTrue(rows.isEmpty)
        case .failure(let code, _): XCTFail("expected success, got \(code)")
        }
    }

    func test_RS_error_maps_to_invalidProductCode() {
        let json = #"{"RS":"ERROR","Data":null}"#.data(using: .utf8)!
        switch client.decode(data: json, requestedProductCode: "ZZZ") {
        case .success: XCTFail("expected failure")
        case .failure(let code, _): XCTAssertEqual(code, .invalidProductCode)
        }
    }

    func test_malformed_json_maps_to_moaParseFailed() {
        let json = "not json at all".data(using: .utf8)!
        switch client.decode(data: json, requestedProductCode: "FV4") {
        case .success: XCTFail("expected failure")
        case .failure(let code, _): XCTAssertEqual(code, .moaParseFailed)
        }
    }
}
