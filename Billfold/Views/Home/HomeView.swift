// HomeView.swift
// The first screen: this month's summary, the latest expenses and a big
// Scan Receipt button. On iPad the summary and the list sit side by side.

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showingSettings = false
    @State private var showingAddForm = false
    @State private var showingScan = false

    var body: some View {
        Group {
            if expenses.isEmpty {
                ContentUnavailableView("No Expenses Yet", systemImage: "doc.text.viewfinder",
                                       description: Text("Scan your first receipt, or tap + to add an expense by hand."))
            } else {
                ScrollView {
                    content.padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Billfold")
        .toolbar { toolbarButtons }
        .safeAreaInset(edge: .bottom) { scanButton }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingAddForm) {
            NavigationStack { ExpenseFormView() }
        }
        .sheet(isPresented: $showingScan) { ScanView() }
    }

    /// iPhone (compact width): stacked. iPad (regular width): side by side.
    private var content: some View {
        let layout = sizeClass == .regular
            ? AnyLayout(HStackLayout(alignment: .top, spacing: Theme.spacing))
            : AnyLayout(VStackLayout(spacing: Theme.spacing))
        return layout {
            SummaryCard(expenses: expenses)
            recentSection
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent").font(.title3).bold()
                Spacer()
                NavigationLink("See All") { ExpenseListView() }
            }
            ForEach(expenses.prefix(5)) { expense in
                NavigationLink {
                    ExpenseFormView(expense: expense)
                } label: {
                    ExpenseRow(expense: expense)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { showingSettings = true } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityIdentifier("settingsButton")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingAddForm = true } label: {
                Label("Add Expense", systemImage: "plus")
            }
            .accessibilityIdentifier("addExpenseButton")
        }
    }

    private var scanButton: some View {
        Button { showingScan = true } label: {
            Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityIdentifier("scanReceiptButton")
    }
}
