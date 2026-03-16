import SwiftUI

struct ContentView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var lockViewModel = AppLockViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if lockViewModel.isUnlocked {
                NavigationStack {
                    DashboardView()
                }
                .environment(viewModel)
                .task {
                    await viewModel.loadDashboard()
                }
            } else {
                LockScreenView(
                    onAuthenticate: { lockViewModel.authenticate() },
                    authFailed: lockViewModel.authFailed
                )
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                lockViewModel.lock()
            } else if newPhase == .active && !lockViewModel.isUnlocked {
                lockViewModel.authenticate()
            }
        }
        .onAppear {
            lockViewModel.authenticate()
        }
    }
}

#Preview {
    ContentView()
}
