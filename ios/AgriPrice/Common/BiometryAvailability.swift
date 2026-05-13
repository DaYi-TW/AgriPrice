import Foundation
import LocalAuthentication

enum BiometryAvailability {
    /// `true` when the device has Face ID / Touch ID enrolled and unlocked.
    /// `false` on the simulator, on devices without biometry, or when biometry
    /// is locked out / disabled in Settings.
    static func isAvailable() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }
}
