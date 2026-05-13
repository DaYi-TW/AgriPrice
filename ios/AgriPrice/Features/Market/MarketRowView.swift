import SwiftUI

struct MarketRowView: View {
    let row: MarketPriceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(row.marketName)
                    .font(.headline)
                Spacer()
                Text(dateLabel)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
            HStack(spacing: 12) {
                priceCell(label: "上價", value: row.upperPrice)
                priceCell(label: "中價", value: row.middlePrice)
                priceCell(label: "下價", value: row.lowerPrice)
                priceCell(label: "成交量(公斤)", value: row.volume)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        return fmt.string(from: row.tradeDate)
    }

    private func priceCell(label: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
