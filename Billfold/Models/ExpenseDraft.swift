// ExpenseDraft.swift
// An editable copy of an expense used by the form. Keeping the text fields
// and validation here (not in the view) makes them easy to unit test.

import Foundation

struct ExpenseDraft {
    var title = ""
    var amountText = ""
    var date = Date()
    var category: ExpenseCategory = .other
    var notes = ""
    var currencyCode = Currency.main
    var receiptImageData: Data?

    /// The typed amount as a number, or nil if it is not a valid number.
    /// Commas are removed so "1,250.50" works the way people write it.
    var amount: Double? {
        let cleaned = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value.isFinite else { return nil }
        return value
    }

    var isValid: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAmount = (amount ?? 0) > 0
        return hasTitle && hasAmount
    }

    init() {}

    /// Starts from an existing expense, for editing.
    init(expense: Expense) {
        title = expense.title
        amountText = String(format: "%.2f", expense.amount)
        date = expense.date
        category = expense.category
        notes = expense.notes
        currencyCode = expense.currencyCode
        receiptImageData = expense.receiptImageData
    }

    /// Starts from a scanned receipt. Missing values stay empty for the user to fill in.
    init(parsed: ParsedReceipt, imageData: Data?) {
        title = parsed.merchant ?? ""
        if let total = parsed.total {
            amountText = String(format: "%.2f", total)
        }
        date = parsed.date ?? Date()
        category = CategoryGuesser.guess(from: parsed.merchant)
        // A "$" receipt is saved in dollars; with no sign on the receipt, the main currency is used.
        currencyCode = parsed.currencyCode ?? Currency.main
        receiptImageData = imageData
    }

    /// Copies the draft into a SwiftData object (new or existing).
    func apply(to expense: Expense) {
        expense.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.amount = amount ?? 0
        expense.date = date
        expense.category = category
        expense.notes = notes
        expense.currencyCode = currencyCode
        expense.receiptImageData = receiptImageData
    }
}
