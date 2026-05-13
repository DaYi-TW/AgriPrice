import XCTest
@testable import AgriPrice

final class ROCDateFormatterTests: XCTestCase {

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func test_string_from_date_uses_ROC_year() {
        let d = makeDate(year: 2018, month: 7, day: 1)
        XCTAssertEqual(ROCDateFormatter.string(from: d), "107.07.01")
    }

    func test_string_from_date_zero_pads_month_and_day() {
        let d = makeDate(year: 2026, month: 1, day: 5)
        XCTAssertEqual(ROCDateFormatter.string(from: d), "115.01.05")
    }

    func test_date_from_string_round_trips() {
        let original = makeDate(year: 2024, month: 2, day: 29)
        let roc = ROCDateFormatter.string(from: original)
        XCTAssertEqual(roc, "113.02.29")
        let back = ROCDateFormatter.date(from: roc)
        XCTAssertNotNil(back)
        XCTAssertEqual(Calendar.current.compare(original, to: back!, toGranularity: .day), .orderedSame)
    }

    func test_date_from_string_returns_nil_for_malformed_input() {
        XCTAssertNil(ROCDateFormatter.date(from: "2024-07-01"))
        XCTAssertNil(ROCDateFormatter.date(from: ""))
        XCTAssertNil(ROCDateFormatter.date(from: "107/07/01"))
    }
}
