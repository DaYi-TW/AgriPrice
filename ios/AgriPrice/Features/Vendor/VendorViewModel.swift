import Foundation
import SwiftData

@MainActor
@Observable
final class VendorViewModel {

    enum LoadState {
        case loggedOut
        case loading
        case loaded(VendorScrapeData)
    }

    // Form fields
    var supplyNo: String = ""
    var supplySub: String = ""
    var password: String = ""
    var rememberCredential: Bool = false

    // UI state
    private(set) var state: LoadState = .loggedOut
    var errorMessage: String?
    var rememberToggleError: String?

    private let api: VendorAPIClientProtocol
    private let keychain: KeychainStoreProtocol
    private let isBiometryAvailable: () -> Bool
    private var inflight: Task<Void, Never>?

    init(
        api: VendorAPIClientProtocol = VendorAPIClient.shared,
        keychain: KeychainStoreProtocol = KeychainStore.shared,
        isBiometryAvailable: @escaping () -> Bool = BiometryAvailability.isAvailable
    ) {
        self.api = api
        self.keychain = keychain
        self.isBiometryAvailable = isBiometryAvailable
    }

    // MARK: - Profile bootstrap

    /// Pull 供應代號 / 小代號 / rememberCredential from SwiftData. Only fills empty
    /// fields so it doesn't clobber user edits.
    func hydrate(from context: ModelContext) {
        let descriptor = FetchDescriptor<VendorQueryProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        guard let profile = profiles.first else { return }
        if supplyNo.isEmpty { supplyNo = profile.supplierCode }
        if supplySub.isEmpty { supplySub = profile.subCode }
        if !rememberCredential { rememberCredential = profile.rememberCredential }
    }

    /// Drop result and return to login form (user tapped 重新查詢).
    func logout() {
        inflight?.cancel()
        state = .loggedOut
        errorMessage = nil
        password = ""
    }

    // MARK: - Toggle handling

    func setRememberCredential(_ on: Bool) {
        if on {
            guard isBiometryAvailable() else {
                rememberCredential = false
                rememberToggleError = "此裝置未設定 Face ID / Touch ID"
                return
            }
            rememberToggleError = nil
            rememberCredential = true
        } else {
            // Synchronous delete before flipping the flag (FR-008, SC-004).
            try? keychain.delete(account: keychainAccount)
            rememberCredential = false
            rememberToggleError = nil
        }
    }

    // MARK: - Query

    func query(context: ModelContext) {
        inflight?.cancel()
        errorMessage = nil
        state = .loading

        let no = supplyNo
        let sub = supplySub
        let pw = password
        let remember = rememberCredential

        inflight = Task { [weak self] in
            guard let self else { return }
            // Try Keychain pre-fill if the user left password blank and opted in.
            let effectivePassword: String
            if pw.isEmpty && remember {
                do {
                    effectivePassword = try await self.keychain.read(
                        account: self.keychainAccount,
                        reason: "解鎖以讀取供應商密碼"
                    )
                } catch {
                    if Task.isCancelled { return }
                    self.state = .loggedOut
                    self.errorMessage = nil
                    return
                }
            } else {
                effectivePassword = pw
            }

            let result = await self.api.scrape(
                supplyNo: no,
                supplySub: sub,
                password: effectivePassword
            )
            if Task.isCancelled { return }

            switch result {
            case .success(let payload):
                self.state = .loaded(payload)
                self.errorMessage = nil
                self.persistProfile(context: context, remember: remember)
                if remember {
                    try? self.keychain.save(password: effectivePassword, account: self.keychainAccount)
                }
                self.password = ""
            case .failure(let code, let message):
                self.state = .loggedOut
                self.errorMessage = message
                if code == .authFailed {
                    self.password = ""
                }
            }
        }
    }

    // MARK: - Helpers

    var keychainAccount: String { "\(supplyNo)-\(supplySub)" }

    var canSubmit: Bool {
        !supplyNo.isEmpty && !supplySub.isEmpty &&
        (!password.isEmpty || (rememberCredential && keychain.contains(account: keychainAccount)))
    }

    var resultData: VendorScrapeData? {
        if case .loaded(let data) = state { return data }
        return nil
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    private func persistProfile(context: ModelContext, remember: Bool) {
        let descriptor = FetchDescriptor<VendorQueryProfile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if let profile = existing.first {
            profile.supplierCode = supplyNo
            profile.subCode = supplySub
            profile.rememberCredential = remember
            profile.updatedAt = .now
        } else {
            context.insert(
                VendorQueryProfile(
                    supplierCode: supplyNo,
                    subCode: supplySub,
                    rememberCredential: remember,
                    updatedAt: .now
                )
            )
        }
        try? context.save()
    }
}
