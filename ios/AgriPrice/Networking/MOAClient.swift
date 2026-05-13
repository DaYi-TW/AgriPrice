import Foundation

protocol MOAClientProtocol {
    func fetchPrices(
        productCode: String,
        startDate: Date,
        endDate: Date
    ) async -> APIResult<[MarketPriceRecord]>
}

final class MOAClient: MOAClientProtocol {
    static let shared = MOAClient()

    private let baseURL = URL(string: "https://data.moa.gov.tw/api/v1/AgriProductsTransType/")!
    private let session: URLSession
    private let productNameLookup: (String) -> String?

    init(
        session: URLSession = .shared,
        productNameLookup: @escaping (String) -> String? = { _ in nil }
    ) {
        self.session = session
        self.productNameLookup = productNameLookup
    }

    func fetchPrices(
        productCode: String,
        startDate: Date,
        endDate: Date
    ) async -> APIResult<[MarketPriceRecord]> {
        guard startDate <= endDate else {
            return .failure(.invalidDateRange)
        }
        guard let url = makeURL(productCode: productCode, startDate: startDate, endDate: endDate) else {
            return .failure(.unknownError)
        }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch is CancellationError {
            return .failure(.unknownError)
        } catch {
            return .failure(.networkError)
        }

        return decode(data: data, requestedProductCode: productCode)
    }

    private func makeURL(productCode: String, startDate: Date, endDate: Date) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "Start_time", value: ROCDateFormatter.string(from: startDate)),
            URLQueryItem(name: "End_time",   value: ROCDateFormatter.string(from: endDate)),
            URLQueryItem(name: "CropCode",   value: productCode)
        ]
        return components?.url
    }

    func decode(data: Data, requestedProductCode: String) -> APIResult<[MarketPriceRecord]> {
        let response: MOAResponse
        do {
            response = try JSONDecoder().decode(MOAResponse.self, from: data)
        } catch {
            return .failure(.moaParseFailed)
        }

        guard response.RS == "OK" else {
            if response.RS.localizedCaseInsensitiveContains("ERROR") {
                return .failure(.invalidProductCode)
            }
            return .failure(.moaParseFailed)
        }

        let rows = response.Data ?? []
        let records = rows.compactMap { row -> MarketPriceRecord? in
            guard let tradeDate = ROCDateFormatter.date(from: row.TransDate) else { return nil }
            let displayName = productNameLookup(row.CropCode) ?? row.CropName
            return MarketPriceRecord(
                productCode: row.CropCode,
                productName: displayName,
                marketCode: row.MarketCode,
                marketName: row.MarketName,
                tradeDate: tradeDate,
                upperPrice: row.Upper_Price,
                middlePrice: row.Middle_Price,
                lowerPrice: row.Lower_Price,
                averagePrice: row.Avg_Price,
                volume: row.Trans_Quantity
            )
        }
        return .success(records)
    }
}
