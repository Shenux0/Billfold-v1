// ExpenseListView.swift
// Every expense, newest first, with search and a category filter.
// Swipe or long-press a row to delete it; tap it to edit.

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var categoryFilter: ExpenseCategory?
    @State private var editingExpense: Expense?

    /// Filtering in memory is fine for a personal expense list and avoids dynamic predicates.
    private var filtered: [Expense] {
        expenses.filter { expense in
            let matchesCategory = categoryFilter == nil || expense.category == categoryFilter
            let matchesSearch = searchText.isEmpty || expense.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { expense in
                NavigationLink {
                    ExpenseFormView(expense: expense)
                } label: {
                    ExpenseRow(expense: expense)
                }
                .accessibilityIdentifier("expenseRow")
                .swipeActions {
                    Button(role: .destructive) { delete(expense) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button { editingExpense = expense } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { delete(expense) } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .accessibilityIdentifier("expenseList")
        .navigationTitle("Expenses")
        .searchable(text: $searchText, prompt: "Search expenses")
        .toolbar { filterMenu }
        .navigationDestination(item: $editingExpense) { expense in
            ExpenseFormView(expense: expense)
        }
        .overlay { emptyState }
    }

    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Category", selection: $categoryFilter) {
                    Text("All").tag(ExpenseCategory?.none)
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.title, systemImage: category.symbol)
                            .tag(ExpenseCategory?.some(category))
                    }
                }
            } label: {
                Label("Filter", systemImage: categoryFilter == nil
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if expenses.isEmpty {
            ContentUnavailableView("No Expenses", systemImage: "tray",
                                   description: Text("Expenses you add or scan will appear here."))
        } else if filtered.isEmpty {
            if searchText.isEmpty {
                ContentUnavailableView.search
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func delete(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
        }
    }
}
