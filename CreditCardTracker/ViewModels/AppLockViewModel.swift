import LocalAuthentication
import SwiftUI

@Observable class AppLockViewModel {
    var isUnlocked = false
    var authFailed = false

    func authenticate() {
        authFailed = false
        let context = LAContext()
        var error: NSError?

        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        context.evaluatePolicy(policy, localizedReason: "Autentique-se para acessar seus cartões") { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.isUnlocked = true
                    self.authFailed = false
                } else {
                    self.authFailed = true
                }
            }
        }
    }

    func lock() {
        isUnlocked = false
        authFailed = false
    }
}
