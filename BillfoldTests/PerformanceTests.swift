// PerformanceTests.swift
// Measures time and memory for the parser and the stats on large inputs.
// The numbers from these tests go into the report's testing section.

import XCTest
import SwiftData
@testable import Billfold

final class PerformanceTests: XCTestCase {
    private var container: ModelContainer?

    override func setUpWithError() throws {
        container = try ModelContainer(for: Expense.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    override func tearDown() {
        container = nil
    }

    /// About 2,000 lines: far longer than any real receipt.
    func testParserPerformance() {
        let receipt = [
            "KEELLS SUPER", "No 12, Galle Road, Colombo 03", "Tel 0112345678",
            "Date: 12 Oct 2025", "Milk 1L 450.00", "Bread 220.00", "Rice 5kg 1,350.00",
            "SUBTOTAL 2,020.00", "Discount 20.00", "TOTAL 2,000.00"
        ]
        let lines = Array(repeating: receipt, count: 200).flatMap { $0 }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            _ = ReceiptParser.parse(lines: lines)
        }
    }

    /// 5,000 expenses: years of heavy use.
    func testStatsPerformance() {
        let categories = ExpenseCategory.allCases
        let now = Date()
        let expenses = (0..<5000).map { index in
            Expense(title: "Item \(index)",
                    amount: Double(index % 500) + 0.5,
                    date: now.addingTimeInterval(-Double(index) * 3600),
                    category: categories[index % categories.count])
        }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let month = ExpenseStats.expenses(expenses, in: .month, containing: now)
            _ = ExpenseStats.total(of: month)
            _ = ExpenseStats.totalsByCategory(expenses)
        }
    }
}
