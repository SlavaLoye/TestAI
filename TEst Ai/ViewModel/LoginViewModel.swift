import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var showInvalidEmail: Bool = false

    private let onLogin: () -> Void

    init(onLogin: @escaping () -> Void) {
        self.onLogin = onLogin
    }

    var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let pred = NSPredicate(format: "SELF MATCHES[c] %@", pattern)
        return pred.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func login() {
        let valid = isEmailValid
        showInvalidEmail = !valid
        if valid {
            onLogin()
        }
    }
}
