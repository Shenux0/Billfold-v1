// ExpenseStats.swift
// Pure calculations behind the Home summary and the Insights charts.
// No UI here, so every function can be unit tested with plain arrays.

import Foundation

struct CategoryTotal: Identifiable {
    let category: ExpenseCategory
    let total: Double
    var id: String { category.id }
}

enum ExpenseStats {
    /// Expenses whose date falls in the same week, month or year as `date`.
    nonisolated static func expenses(_ all: [Expense], in period: Period,
                                     containing date: Date, calendar: Calendar = .current) -> [Expense] {
        guard let interval = calendar.dateInterval(of: period.calendarComponent, for: date) else {
            return []
        }
        return all.filter { interval.contains($0.date) }
    }

    nonisolated static func total(of expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// Totals per category, biggest first, categories with 0 left out.
    nonisolated static func totalsByCategory(_ expenses: [Expense]) -> [CategoryTotal] {
        var sums: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            sums[expense.category, default: 0] += expense.amount
        }
        return sums
            .filter { $0.value > 0 }
            .map { CategoryTotal(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
}
