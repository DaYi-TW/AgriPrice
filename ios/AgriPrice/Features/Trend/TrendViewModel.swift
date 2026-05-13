import Foundation
import SwiftData

@MainActor
@Observable
final class TrendViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded(points: [MarketPriceRecord])
        case empty
        case error(message: String)
    }

    let productCode: String
    let productName: String
    let marketCode: String?
    let marketName: String
    let startDate: Date
    let endDate: Date
    private(set) var state: LoadState = .idle

    private let client: MOAClientProtocol

    init(
        productCode: String,
        productName: String,
        marketCode: String?,
        marketName: String,
        startDate: Date,
        endDate: Date,
        client: MOAClientProtocol = MOAClient.shared
    ) {
        self.productCode = productCode
        self.productName = productName
        self.marketCode = marketCode
        self.marketName = marketName
        self.startDate = startDate
        self.endDate = endDate
        self.client = client
    }

    func load(from context: ModelContext) {
        let cached = readCache(from: context)
        if !cached.isEmpty {
            state = .loaded(points: cached)
            return
        }

        state = .loading
        Task { [weak self] in
            guard let self else { return }
            let result = await self.client.fetchPrices(
                productCode: self.productCode,
                startDate: self.startDate,
                endDate: self.endDate
            )
            switch result {
            case .success(let rows):
                let filtered = self.filterForMarket(rows)
                if filtered.isEmpty {
                    self.state = .empty
                } else {
                    for row in filtered { context.insert(row) }
                    try? context.save()
                    self.state = .loaded(points: filtered.sorted { $0.tradeDate < $1.tradeDate })
                }
            case .failure(_, let message):
                self.state = .error(message: message)
            }
        }
    }

    private func readCache(from context: ModelContext) -> [MarketPriceRecord] {
        let productCode = self.productCode
        let marketCode = self.marketCode
        let start = self.startDate
        let end = self.endDate
        let predicate: Predicate<MarketPriceRecord>
        if let marketCode {
            predicate = #Predicate {
                $0.productCode == productCode
                && $0.marketCode == marketCode
                && $0.tradeDate >= start
                && $0.tradeDate <= end
            }
        } else {
            predicate = #Predicate {
                $0.productCode == productCode
                && $0.tradeDate >= start
                && $0.tradeDate <= end
            }
        }
        let descriptor = FetchDescriptor<MarketPriceRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.tradeDate)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func filterForMarket(_ rows: [MarketPriceRecord]) -> [MarketPriceRecord] {
        guard let marketCode else { return rows }
        return rows.filter { $0.marketCode == marketCode }
    }
}
