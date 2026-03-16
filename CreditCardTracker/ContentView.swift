//
//  ContentView.swift
//  CreditCardTracker
//
//  Created by Danilo Carvalho on 12/03/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            DashboardView()
        }
        .environment(viewModel)
        .task {
            await viewModel.loadDashboard()
        }
    }
}

#Preview {
    ContentView()
}
