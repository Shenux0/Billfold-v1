// RootTabView.swift
// The three main tabs. Each tab has its own NavigationStack so going
// deeper in one tab does not affect the others.

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                ExpenseListView()
            }
            .tabItem { Label("Expenses", systemImage: "list.bullet") }

            NavigationStack {
                InsightsView()
            }
            .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
        }
    }
}
