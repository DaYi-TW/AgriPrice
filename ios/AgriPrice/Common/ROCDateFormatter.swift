import Foundation

enum ROCDateFormatter {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .republicOfChina)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
        return cal
    }()

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "y.MM.dd"
        return f
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from rocString: String) -> Date? {
        formatter.date(from: rocString)
    }
}
