import Foundation

enum APIResult<T> {
    case success(T)
    case failure(code: ErrorCode, message: String)

    static func failure(_ code: ErrorCode) -> APIResult<T> {
        .failure(code: code, message: code.userMessage)
    }
}
