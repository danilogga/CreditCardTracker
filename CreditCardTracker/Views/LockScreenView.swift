import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    let onAuthenticate: () -> Void
    let authFailed: Bool

    private var biometryIcon: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "lock.fill"
        }
        return context.biometryType == .faceID ? "faceid" : "touchid"
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.blue)

                    Text("Cartões")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onAuthenticate) {
                        VStack(spacing: 8) {
                            Image(systemName: biometryIcon)
                                .font(.system(size: 44, weight: .light))
                            Text("Autenticar")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    if authFailed {
                        Text("Autenticação falhou. Tente novamente.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}
