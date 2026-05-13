import SwiftUI
import SwiftData
import Charts

struct TrendView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: TrendViewModel?

    private let initialArgs: Args?

    struct Args {
        let productCode: String
        let productName: String
        let marketCode: String?
        let marketName: String
        let startDate: Date
        let endDate: Date
    }

    /// Tab-level entry: no selection yet, show guidance.
    init() {
        self.initialArgs = nil
    }

    /// Drill-down entry from MarketRowView.
    init(
        productCode: String,
        productName: String,
        marketCode: String?,
        marketName: String,
        startDate: Date,
        endDate: Date
    ) {
        self.initialArgs = Args(
            productCode: productCode,
            productName: productName,
            marketCode: marketCode,
            marketName: marketName,
            startDate: startDate,
            endDate: endDate
        )
    }

    var body: some View {
        Group {
            if let viewModel {
                contentBody(viewModel: viewModel)
            } else {
                emptyTabBody
            }
        }
        .background(DesignTokens.Color.pageBackground)
        .navigationTitle("趨勢")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil, let args = initialArgs {
                let vm = TrendViewModel(
                    productCode: args.productCode,
                    productName: args.productName,
                    marketCode: args.marketCode,
                    marketName: args.marketName,
                    startDate: args.startDate,
                    endDate: args.endDate
                )
                vm.load(from: context)
                viewModel = vm
            }
        }
    }

    private var emptyTabBody: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.brandGreen)
                Text("趨勢")
                    .font(.title2.bold())
                Text("請從行情頁面點選市場以查看趨勢")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Color.pageBackground)
        }
    }

    private func contentBody(viewModel: TrendViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                header(viewModel: viewModel)
                content(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func header(viewModel: TrendViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(viewModel.productCode) \(viewModel.productName)")
                .font(.title3.bold())
            Text(viewModel.marketName)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
            Text(dateRangeLabel(start: viewModel.startDate, end: viewModel.endDate))
                .font(.caption)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    @ViewBuilder
    private func content(viewModel: TrendViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        case .empty:
            placeholder("查無此日期區間行情")
        case .error(let message):
            placeholder(message)
        case .loaded(let points):
            priceChart(points)
            volumeChart(points)
        }
    }

    private func priceChart(_ points: [MarketPriceRecord]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("平均價格趨勢")
                .font(.headline)
            Chart {
                ForEach(points, id: \.persistentModelID) { p in
                    if let avg = p.averagePrice {
                        LineMark(
                            x: .value("日期", p.tradeDate),
                            y: .value("均價", avg)
                        )
                        PointMark(
                            x: .value("日期", p.tradeDate),
                            y: .value("均價", avg)
                        )
                    }
                }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: max(1, points.count / 5))) }
            .frame(height: 220)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private func volumeChart(_ points: [MarketPriceRecord]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("成交量(公斤)")
                .font(.headline)
            Chart {
                ForEach(points, id: \.persistentModelID) { p in
                    if let vol = p.volume {
                        BarMark(
                            x: .value("日期", p.tradeDate),
                            y: .value("成交量", vol)
                        )
                    }
                }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: max(1, points.count / 5))) }
            .frame(height: 180)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(DesignTokens.Color.secondaryForeground)
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(14)
            .background(Color.white)
            .cornerRadius(DesignTokens.Radius.card)
    }

    private func dateRangeLabel(start: Date, end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy/MM/dd"
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return fmt.string(from: start)
        }
        return "\(fmt.string(from: start)) ～ \(fmt.string(from: end))"
    }
}
