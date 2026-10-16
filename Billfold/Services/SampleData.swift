// SampleData.swift
// A fixed set of example expenses for demos, screenshots and UI tests.
// Fixed values (not random) mean every run looks exactly the same.

import Foundation
import SwiftData

enum SampleData {
    /// Adds 25 expenses spread over the last 60 days and every category.
    nonisolated static func insert(into context: ModelContext) {
        let items: [(title: String, amount: Double, daysAgo: Int, category: ExpenseCategory)] = [
            ("Keells Super", 3450.00, 0, .food),
            ("PickMe Ride", 620.00, 1, .transport),
            ("Java Lounge", 1180.00, 2, .food),
            ("Dialog Mobile Bill", 1999.00, 3, .bills),
            ("Union Chemists Pharmacy", 845.50, 4, .health),
            ("Scope Cinemas", 1500.00, 5, .entertainment),
            ("Cargills Food City", 2760.25, 7, .food),
            ("Ceypetco Fuel", 4000.00, 8, .transport),
            ("ODEL", 6500.00, 10, .shopping),
            ("Pizza Hut", 2890.00, 12, .food),
            ("Electricity Bill", 3820.00, 14, .bills),
            ("Bus Pass", 1200.00, 16, .transport),
            ("Sarasavi Books", 2150.00, 18, .shopping),
            ("Arpico Supercentre", 5120.75, 21, .food),
            ("Asiri Medical Clinic", 3500.00, 24, .health),
            ("Uber Trip", 980.00, 27, .transport),
            ("Movie Night", 1800.00, 30, .entertainment),
            ("SLT Fibre Internet", 4590.00, 33, .bills),
            ("Barber", 800.00, 36, .other),
            ("Bakery House", 640.00, 39, .food),
            ("Fashion Bug", 3990.00, 43, .shopping),
            ("Taxi to Airport", 5500.00, 47, .transport),
            ("Water Board Bill", 1250.00, 51, .bills),
            ("Birthday Gift", 4200.00, 55, .other),
            ("Games Store", 2600.00, 58, .entertainment)
        ]

        let today = Date()
        for item in items {
            let date = Calendar.current.date(byAdding: .day, value: -item.daysAgo, to: today) ?? today
            context.insert(Expense(title: item.title, amount: item.amount,
                                   date: date, category: item.category))
        }
        try? context.save()
    }
}
