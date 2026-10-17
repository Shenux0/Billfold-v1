// ExpenseStatsTests.swift
// Checks period filtering, totals and per-category totals. Uses a fixed
// calendar and time zone so the results do not depend on the test machine.

import XCTest
import SwiftData
@testable import Billfold

final class ExpenseStatsTests: XCTestCase {
    // SwiftData models are safest to create while a container exists, so keep one alive.
    private var container: ModelContainer?
    private var calendar = Calendar(identifier: .gregorian)

    override func setUpWithError() throws {
        container = try ModelContainer(for: Expense.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.firstWeekday = 2 // Monday
    }

    override func tearDown() {
        container = nil
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func sampleExpenses() -> [Expense] {
        [
            Expense(title: "Lunch", amount: 500, date: day(2026, 10, 14), category: .food),       // Wed, same week
            Expense(title: "Bus", amount: 100, date: day(2026, 10, 12), category: .transport),    // Mon, same week
            Expense(title: "Phone bill", amount: 1500, date: day(2026, 10, 2), category: .bills), // same month
            Expense(title: "Shoes", amount: 4000, date: day(2026, 3, 20), category: .shopping),   // same year
            Expense(title: "Dinner", amount: 900, date: day(2025, 10, 14), category: .food)       // last year
        ]
    }

    func testWeekFilter() {
        let result = ExpenseStats.expenses(sampleExpenses(), in: .week,
                                           containing: day(2026, 10, 15), calendar: calendar)
        XCTAssertEqual(Set(result.map(\.title)), ["Lunch", "Bus"])
    }

    func testMonthFilter() {
        let result = ExpenseStats.expenses(sampleExpenses(), in: .month,
                                           containing: day(2026, 10, 15), calendar: calendar)
        XCTAssertEqual(Set(result.map(\.title)), ["Lunch", "Bus", "Phone bill"])
    }

    func testYearFilter() {
        let result = ExpenseStats.expenses(sampleExpenses(), in: .year,
                                           containing: day(2026, 10, 15), calendar: calendar)
        XCTAssertEqual(result.count, 4)
        XCTAssertFalse(result.contains { $0.title == "Dinner" })
    }

    func testTotal() {
        XCTAssertEqual(ExpenseStats.total(of: sampleExpenses()), 7000, accuracy: 0.001)
        XCTAssertEqual(ExpenseStats.total(of: []), 0)
    }

    func testTotalsByCategoryAreSortedBiggestFirst() {
        let totals = ExpenseStats.totalsByCategory(sampleExpenses())
        XCTAssertEqual(totals.map(\.category), [.shopping, .bills, .food, .transport])
        XCTAssertEqual(totals.first(where: { $0.category == .food })?.total ?? 0, 1400, accuracy: 0.001)
    }

    func testCurrencyFilterAndTotalsByCurrency() {
        let expenses = [
            Expense(title: "Rice", amount: 1200, currencyCode: "LKR"),
            Expense(title: "Coffee", amount: 4.5, currencyCode: "USD"),
            Expense(title: "Book", amount: 20, currencyCode: "USD"),
            Expense(title: "Train", amount: 10, currencyCode: "EUR")
        ]
        let rupees = ExpenseStats.expenses(expenses, inCurrency: "LKR")
        XCTAssertEqual(rupees.map(\.title), ["Rice"])

        let others = ExpenseStats.totalsByCurrency(expenses.filter { $0.currencyCode != "LKR" })
        XCTAssertEqual(others.map(\.code), ["EUR", "USD"])
        XCTAssertEqual(others.last?.total ?? 0, 24.5, accuracy: 0.001)
    }

    func testTotalsByCategoryLeaveOutZeros() {
        let expenses = [
            Expense(title: "Free sample", amount: 0, category: .health),
            Expense(title: "Coffee", amount: 350, category: .food)
        ]
        let totals = ExpenseStats.totalsByCategory(expenses)
        XCTAssertEqual(totals.map(\.category), [.food])
    }
}
