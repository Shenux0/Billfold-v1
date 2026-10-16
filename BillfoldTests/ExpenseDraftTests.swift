// ExpenseDraftTests.swift
// Checks how the form turns typed text into an amount, when it allows
// saving, and how a scanned receipt becomes a draft.

import XCTest
import SwiftData
@testable import Billfold

final class ExpenseDraftTests: XCTestCase {
    private var container: ModelContainer?

    override func setUpWithError() throws {
        container = try ModelContainer(for: Expense.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    override func tearDown() {
        container = nil
    }

    func testAmountParsing() {
        var draft = ExpenseDraft()
        draft.amountText = "1,250.50"
        XCTAssertEqual(draft.amount, 1250.50)
        draft.amountText = " 99 "
        XCTAssertEqual(draft.amount, 99)
        draft.amountText = "abc"
        XCTAssertNil(draft.amount)
        draft.amountText = ""
        XCTAssertNil(draft.amount)
    }

    func testIsValidNeedsTitleAndPositiveAmount() {
        var draft = ExpenseDraft()
        XCTAssertFalse(draft.isValid)

        draft.title = "Lunch"
        XCTAssertFalse(draft.isValid, "no amount yet")

        draft.amountText = "0"
        XCTAssertFalse(draft.isValid, "zero is not allowed")

        draft.amountText = "450"
        XCTAssertTrue(draft.isValid)

        draft.title = "   "
        XCTAssertFalse(draft.isValid, "a blank title is not allowed")
    }

    func testInitFromParsedReceipt() {
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        let parsed = ParsedReceipt(merchant: "Keells Super", total: 1250.5, date: date)
        let draft = ExpenseDraft(parsed: parsed, imageData: Data([1, 2, 3]))

        XCTAssertEqual(draft.title, "Keells Super")
        XCTAssertEqual(draft.amountText, "1250.50")
        XCTAssertEqual(draft.amount, 1250.5)
        XCTAssertEqual(draft.date, date)
        XCTAssertEqual(draft.category, .food)
        XCTAssertEqual(draft.receiptImageData, Data([1, 2, 3]))
    }

    func testInitFromEmptyParsedReceipt() {
        let draft = ExpenseDraft(parsed: ParsedReceipt(), imageData: nil)
        XCTAssertEqual(draft.title, "")
        XCTAssertEqual(draft.amountText, "")
        XCTAssertEqual(draft.category, .other)
        XCTAssertFalse(draft.isValid)
    }

    func testApplyCopiesFieldsIntoExpense() {
        var draft = ExpenseDraft()
        draft.title = "  Taxi  "
        draft.amountText = "800"
        draft.category = .transport
        draft.notes = "Airport"

        let expense = Expense(title: "", amount: 0)
        draft.apply(to: expense)

        XCTAssertEqual(expense.title, "Taxi")
        XCTAssertEqual(expense.amount, 800)
        XCTAssertEqual(expense.category, .transport)
        XCTAssertEqual(expense.notes, "Airport")
    }

    func testRoundTripThroughExpense() {
        let expense = Expense(title: "Books", amount: 2400, category: .shopping, notes: "Course")
        let draft = ExpenseDraft(expense: expense)
        XCTAssertEqual(draft.title, "Books")
        XCTAssertEqual(draft.amount, 2400)
        XCTAssertEqual(draft.category, .shopping)
        XCTAssertEqual(draft.notes, "Course")
    }
}
