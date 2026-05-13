import SwiftUI

struct DateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var start: Date
    @State private var end: Date
    @State private var validationMessage: String?

    let onConfirm: (Date, Date) -> Void

    init(start: Date, end: Date, onConfirm: @escaping (Date, Date) -> Void) {
        _start = State(initialValue: start)
        _end = State(initialValue: end)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                presetRow

                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("開始日期", selection: $start, in: ...Date(), displayedComponents: .date)
                    DatePicker("結束日期", selection: $end, in: ...Date(), displayedComponents: .date)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(DesignTokens.Radius.card)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DesignTokens.Color.pageBackground)
            .navigationTitle("選擇日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確定") {
                        if let msg = validate() {
                            validationMessage = msg
                        } else {
                            onConfirm(start, end)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                preset(label: "今天") { (.now, .now) }
                preset(label: "本月") {
                    let cal = Calendar.current
                    let s = cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
                    return (s, .now)
                }
                preset(label: "近 7 日") { (Date().addingTimeInterval(-7 * 86400), .now) }
                preset(label: "近 30 日") { (Date().addingTimeInterval(-30 * 86400), .now) }
                preset(label: "近 90 日") { (Date().addingTimeInterval(-90 * 86400), .now) }
            }
        }
    }

    private func preset(label: String, range: @escaping () -> (Date, Date)) -> some View {
        Button {
            let (s, e) = range()
            start = Calendar.current.startOfDay(for: s)
            end = Calendar.current.startOfDay(for: e)
            validationMessage = nil
        } label: {
            Text(label)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DesignTokens.Color.brandTint)
                .foregroundStyle(DesignTokens.Color.brandGreen)
                .cornerRadius(DesignTokens.Radius.chip)
        }
        .buttonStyle(.plain)
    }

    private func validate() -> String? {
        if start > end { return "開始日期不可晚於結束日期" }
        if end > Date().addingTimeInterval(86400) { return "結束日期不可晚於今日" }
        return nil
    }
}
