import Foundation
import os

protocol VendorAPIClientProtocol {
    func scrape(
        supplyNo: String,
        supplySub: String,
        password: String
    ) async -> APIResult<VendorScrapeData>
}

/// chill-api request body. `fileprivate` so the password-bearing struct cannot
/// escape this file. Constitution III + research.md §3.
fileprivate struct VendorScrapeRequest: Encodable {
    let credentials: Credentials
    struct Credentials: Encodable {
        let supplyNo: String
        let supplySub: String
        let password: String
        enum CodingKeys: String, CodingKey {
            case supplyNo = "supply_no"
            case supplySub = "supply_sub"
            case password
        }
    }
}

final class VendorAPIClient: VendorAPIClientProtocol {
    static let shared = VendorAPIClient()

    private let endpoint = URL(string: "https://chill-api-240848983153.asia-east1.run.app/api/scrape")!
    private let session: URLSession
    private let logger = Logger(subsystem: "com.agriprice.app", category: "vendor-api")

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            self.session = URLSession(configuration: config)
        }
    }

    func scrape(
        supplyNo: String,
        supplySub: String,
        password: String
    ) async -> APIResult<VendorScrapeData> {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let body = VendorScrapeRequest(
                credentials: .init(supplyNo: supplyNo, supplySub: supplySub, password: password)
            )
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            log(status: -1, errorCode: "ENCODE_FAILED")
            return .failure(.internalError)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            return .failure(.networkError)
        } catch {
            log(status: -1, errorCode: "URL_ERROR")
            return .failure(.networkError)
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1
        return decode(status: status, data: data)
    }

    func decode(status: Int, data: Data) -> APIResult<VendorScrapeData> {
        // 422 uses FastAPI's default {"detail":[…]} shape; treat as INTERNAL_ERROR.
        guard status != 422 else {
            log(status: status, errorCode: "INTERNAL_ERROR")
            return .failure(.internalError)
        }

        let envelope: VendorScrapeResponse
        do {
            envelope = try JSONDecoder().decode(VendorScrapeResponse.self, from: data)
        } catch {
            log(status: status, errorCode: "DECODE_FAILED")
            return .failure(.internalError)
        }

        log(status: status, errorCode: envelope.errorCode)

        if status == 200 && envelope.success, let payload = envelope.data {
            return .success(payload)
        }

        switch envelope.errorCode {
        case "AUTH_FAILED":    return .failure(.authFailed)
        case "UPSTREAM_ERROR": return .failure(.upstreamError)
        case "INTERNAL_ERROR": return .failure(.internalError)
        default:               return .failure(.internalError)
        }
    }

    /// Logs only HTTP status + error_code. **Never** the request body or password.
    private func log(status: Int, errorCode: String?) {
        logger.info("chill-api method=POST status=\(status, privacy: .public) error_code=\(errorCode ?? "nil", privacy: .public)")
    }
}
