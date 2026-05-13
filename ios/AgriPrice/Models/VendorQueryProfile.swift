import Foundation
import SwiftData

/// Per-device vendor identity. Password lives in Keychain (constitution III), never here.
@Model
final class VendorQueryProfile {
    var supplierCode: String
    var subCode: String
    var rememberCredential: Bool
    var updatedAt: Date

    init(
        supplierCode: String,
        subCode: String,
        rememberCredential: Bool = false,
        updatedAt: Date = .now
    ) {
        self.supplierCode = supplierCode
        self.subCode = subCode
        self.rememberCredential = rememberCredential
        self.updatedAt = updatedAt
    }
}
