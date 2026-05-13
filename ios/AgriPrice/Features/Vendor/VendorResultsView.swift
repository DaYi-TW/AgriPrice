import SwiftUI

struct VendorResultsView: View {
    let data: VendorScrapeData
    let supplyNo: String
    let supplySub: String
    let onLogout: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                totalsRow
                marketsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(DesignTokens.Color.pageBackground)
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("供應商")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
                Text("\(supplyNo)-\(supplySub)")
                    .font(.headline)
            }
            Spacer()
            Button("重新查詢", action: onLogout)
                .font(.subheadline.bold())
                .foregroundStyle(DesignTokens.Color.brandGreen)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private var totalsRow: some View {
        HStack(spacing: 12) {
            totalCard(title: "今日總利潤", value: data.todayTotalProfit)
            totalCard(title: "本年累計",   value: data.yearTotal)
        }
    }

    private func totalCard(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
            Text(currency(value))
                .font(.title3.bold())
                .foregroundStyle(DesignTokens.Color.brandGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private var marketsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("各市場成交")
                .font(.headline)
            if data.marketData.isEmpty {
                Text("今天無銷售資料")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(DesignTokens.Radius.card)
            } else {
                ForEach(data.marketData) { row in
                    marketRow(row)
                }
            }
        }
    }

    private func marketRow(_ row: VendorMarketRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.market)
                    .font(.subheadline.bold())
                Text(row.productName)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("均價 \(price(row.averagePrice))")
                    .font(.subheadline.bold())
                Text("數量 \(quantity(row.quantity))")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private func currency(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        return "NT$ " + (fmt.string(from: NSNumber(value: value)) ?? "\(Int(value))")
    }

    private func price(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func quantity(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
