import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = MarketViewModel()
    @State private var showProductPicker = false
    @State private var showDateSheet = false

    @Query private var allProducts: [ProductItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    selectionHeader
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(DesignTokens.Color.pageBackground)
            .navigationTitle("行情")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProductPicker) {
                ProductPickerSheet { picked in
                    viewModel.setSelection(product: picked)
                    viewModel.reload(into: context)
                }
            }
            .sheet(isPresented: $showDateSheet) {
                DateRangeSheet(start: viewModel.startDate, end: viewModel.endDate) { s, e in
                    viewModel.startDate = s
                    viewModel.endDate = e
                    viewModel.reload(into: context)
                }
            }
            .onAppear {
                if viewModel.selectedProduct == nil, let first = defaultProduct() {
                    viewModel.setSelection(product: first)
                    viewModel.reload(into: context)
                }
            }
        }
    }

    private func defaultProduct() -> ProductItem? {
        allProducts
            .sorted { a, b in
                if a.isFavorite != b.isFavorite { return a.isFavorite && !b.isFavorite }
                if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
                return a.name < b.name
            }
            .first
    }

    // MARK: - Subviews

    private var selectionHeader: some View {
        HStack(spacing: 12) {
            Button {
                showProductPicker = true
            } label: {
                HStack {
                    Image(systemName: "leaf.fill")
                    Text(viewModel.selectedProduct.map { "\($0.code) \($0.name)" } ?? "選擇品項")
                        .lineLimit(1)
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Color.brandGreen)
                .foregroundStyle(.white)
                .cornerRadius(DesignTokens.Radius.chip)
            }
            .buttonStyle(.plain)

            Button {
                showDateSheet = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text(dateRangeLabel)
                        .lineLimit(1)
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DesignTokens.Color.brandTint)
                .foregroundStyle(DesignTokens.Color.brandGreen)
                .cornerRadius(DesignTokens.Radius.chip)
            }
            .buttonStyle(.plain)
        }
    }

    private var dateRangeLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        if Calendar.current.isDate(viewModel.startDate, inSameDayAs: viewModel.endDate) {
            return fmt.string(from: viewModel.startDate)
        }
        return "\(fmt.string(from: viewModel.startDate)) ～ \(fmt.string(from: viewModel.endDate))"
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.state {
        case .idle:
            placeholder(text: "選擇品項以查詢行情")
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 120)
        case .empty:
            placeholder(text: "查無此日期區間行情")
        case .error(let message):
            placeholder(text: message)
        case .loaded:
            if let s = viewModel.summary {
                MarketSummaryCard(high: s.high, average: s.average, low: s.low)
            }
            ForEach(viewModel.rowsByMarket, id: \.persistentModelID) { row in
                NavigationLink {
                    TrendView(
                        productCode: row.productCode,
                        productName: row.productName,
                        marketCode: row.marketCode,
                        marketName: row.marketName,
                        startDate: viewModel.startDate,
                        endDate: viewModel.endDate
                    )
                } label: {
                    MarketRowView(row: row)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func placeholder(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(DesignTokens.Color.secondaryForeground)
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(14)
            .background(Color.white)
            .cornerRadius(DesignTokens.Radius.card)
    }
}
