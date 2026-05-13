import Foundation
import SwiftData

@MainActor
@Observable
final class MarketViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded(rows: [MarketPriceRecord])
        case empty
        case error(message: String)
    }

    var selectedProduct: ProductItem?
    var startDate: Date
    var endDate: Date
    private(set) var state: LoadState = .idle

    private let client: MOAClientProtocol
    private var inflight: Task<Void, Never>?

    init(
        client: MOAClientProtocol = MOAClient.shared,
        startDate: Date = .now,
        endDate: Date = .now
    ) {
        self.client = client
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.startOfDay(for: endDate)
    }

    func setSelection(product: ProductItem, startDate: Date? = nil, endDate: Date? = nil) {
        self.selectedProduct = product
        if let startDate { self.startDate = Calendar.current.startOfDay(for: startDate) }
        if let endDate   { self.endDate   = Calendar.current.startOfDay(for: endDate) }
    }

    func reload(into context: ModelContext) {
        guard let product = selectedProduct else {
            state = .idle
            return
        }
        let productCode = product.code
        let productName = product.name
        let start = startDate
        let end = endDate

        inflight?.cancel()
        state = .loading

        inflight = Task { [weak self] in
            guard let self else { return }
            let result = await self.client.fetchPrices(
                productCode: productCode,
                startDate: start,
                endDate: end
            )
            if Task.isCancelled { return }

            switch result {
            case .success(let rows) where rows.isEmpty:
                self.state = .empty
            case .success(let rows):
                self.persist(rows: rows, productName: productName, into: context)
                self.appendRecentQuery(
                    productCode: productCode,
                    productName: productName,
                    into: context
                )
                self.state = .loaded(rows: rows)
            case .failure(_, let message):
                self.state = .error(message: message)
            }
        }
    }

    // MARK: - Derived UI values

    var rowsByMarket: [MarketPriceRecord] {
        if case .loaded(let rows) = state {
            return rows.sorted { $0.marketName < $1.marketName }
        }
        return []
    }

    var summary: (high: Double?, average: Double?, low: Double?)? {
        guard case .loaded(let rows) = state, !rows.isEmpty else { return nil }
        let averages = rows.compactMap { $0.averagePrice }
        guard !averages.isEmpty else { return (nil, nil, nil) }
        let high = averages.max()
        let low = averages.min()
        let avg = averages.reduce(0, +) / Double(averages.count)
        return (high, avg, low)
    }

    // MARK: - Persistence

    private func persist(rows: [MarketPriceRecord], productName: String, into context: ModelContext) {
        for row in rows {
            row.productName = productName
            context.insert(row)
        }
        try? context.save()
    }

    private func appendRecentQuery(productCode: String, productName: String, into context: ModelContext) {
        let entry = RecentQuery(
            productCode: productCode,
            productName: productName,
            startDate: startDate,
            endDate: endDate
        )
        context.insert(entry)
        try? context.save()
    }
}
