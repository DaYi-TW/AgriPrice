import SwiftUI

struct MarketSummaryCard: View {
    let high: Double?
    let average: Double?
    let low: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("區間摘要")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.85))

            HStack {
                cell(label: "最高均價", value: high)
                Divider().background(.white.opacity(0.4))
                cell(label: "平均均價", value: average)
                Divider().background(.white.opacity(0.4))
                cell(label: "最低均價", value: low)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [DesignTokens.Color.brandGreen, DesignTokens.Color.brandGreenLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignTokens.Radius.card)
    }

    private func cell(label: String, value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
