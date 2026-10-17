// Expense.swift
// The one thing Billfold saves: a single expense, stored on the device
// with SwiftData. The receipt photo is optional.

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var categoryRaw: String
    var notes: String
    // Photos are large, so SwiftData keeps them in separate files instead of inside the database.
    @Attribute(.externalStorage) var receiptImageData: Data?

    // Computed, not stored. The enum is stored as a raw string because that is the safest way in SwiftData.
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(title: String, amount: Double, date: Date = .now,
         category: ExpenseCategory = .other, notes: String = "", receiptImageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.date = date
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.receiptImageData = receiptImageData
    }
}
