import SwiftUI

struct MonthSelectorView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private var displayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: viewModel.month) else { return viewModel.month }

        let display = DateFormatter()
        display.dateFormat = "MMM yyyy"
        display.locale = Locale(identifier: "pt_BR")
        let raw = display.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.navigateToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
            .disabled(viewModel.isLoadingDashboard)

            Text(displayLabel)
                .font(.headline)
                .frame(minWidth: 120)
                .multilineTextAlignment(.center)

            Button {
                viewModel.navigateToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
            }
            .disabled(viewModel.isLoadingDashboard)
        }
    }
}
