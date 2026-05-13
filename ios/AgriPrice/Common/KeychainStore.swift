import Foundation
import Security
import LocalAuthentication

/// Biometry-gated Keychain wrapper for the vendor password.
///
/// Constitution III: the password lives only here, never in UserDefaults,
/// SwiftData, plists, log lines, or analytics. Reads require Face ID / Touch ID.
protocol KeychainStoreProtocol {
    func save(password: String, account: String) throws
    func read(account: String, reason: String) async throws -> String
    func delete(account: String) throws
    func contains(account: String) -> Bool
}

enum KeychainError: Error, Equatable {
    case unhandled(OSStatus)
    case accessControlCreationFailed
    case itemNotFound
    case decodingFailed
    case authenticationCancelled
    case authenticationFailed
}

final class KeychainStore: KeychainStoreProtocol {
    static let shared = KeychainStore()

    private let service = "agriprice.vendor.password"

    func save(password: String, account: String) throws {
        // Always overwrite — delete any prior entry first so the access-control
        // flags don't drift between writes.
        try? delete(account: account)

        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            throw KeychainError.accessControlCreationFailed
        }

        guard let data = password.data(using: .utf8) else {
            throw KeychainError.decodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
            kSecValueData as String:       data,
            kSecAttrAccessControl as String: access
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    func read(account: String, reason: String) async throws -> String {
        let context = LAContext()
        context.localizedReason = reason

        let query: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          service,
            kSecAttrAccount as String:          account,
            kSecReturnData as String:           true,
            kSecMatchLimit as String:           kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var item: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &item)
                switch status {
                case errSecSuccess:
                    if let data = item as? Data, let pw = String(data: data, encoding: .utf8) {
                        continuation.resume(returning: pw)
                    } else {
                        continuation.resume(throwing: KeychainError.decodingFailed)
                    }
                case errSecItemNotFound:
                    continuation.resume(throwing: KeychainError.itemNotFound)
                case errSecUserCanceled, errSecAuthFailed:
                    continuation.resume(throwing: KeychainError.authenticationCancelled)
                default:
                    continuation.resume(throwing: KeychainError.unhandled(status))
                }
            }
        }
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }

    func contains(account: String) -> Bool {
        // Use kSecUseAuthenticationUI=fail so we don't trigger a biometric prompt
        // just to check existence.
        let query: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrService as String:        service,
            kSecAttrAccount as String:        account,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail,
            kSecReturnData as String:         false
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }
}
