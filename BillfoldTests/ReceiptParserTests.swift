// ReceiptParserTests.swift
// Checks each parser rule with small fake receipts, including the messy
// cases real OCR produces (split lines, phone numbers, subtotals).

import XCTest
@testable import Billfold

final class ReceiptParserTests: XCTestCase {

    // MARK: Total

    func testFindsTotalWithThousandsSeparator() {
        let lines = ["KEELLS SUPER", "Milk 450.00", "Bread 800.00", "TOTAL 1,250.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 1250.00)
    }

    func testIgnoresSubtotal() {
        // The subtotal is bigger here, so picking it would be a visible mistake.
        let lines = ["Shop", "SUBTOTAL 1,300.00", "Discount 50.00", "TOTAL 1,250.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 1250.00)
    }

    func testTotalOnTheLineAfterTheLabel() {
        let lines = ["Shop", "Item 900.00", "Total", "1,250.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 1250.00)
    }

    func testAmountDueCountsAsTotal() {
        let lines = ["Shop", "Item 300.00", "Amount Due: 320.50"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 320.50)
    }

    func testFallsBackToLargestAmount() {
        let lines = ["Shop", "Item 100.00", "Item 250.00", "Cash 500.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 500.00)
    }

    func testIgnoresNumbersWithoutDecimals() {
        let lines = ["Shop", "Tel 0112345678", "Bill No 99812", "Item 99.50"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 99.50)
    }

    func testNetAmountCountsAsTotal() {
        let lines = ["Shop", "Item 900.00", "Cash 2,000.00", "NET AMOUNT 950.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 950.00)
    }

    func testJoinsStraySpaceAroundDecimalPoint() {
        XCTAssertEqual(ReceiptParser.amounts(in: "TOTAL 1,250. 00"), [1250.00])
        XCTAssertEqual(ReceiptParser.amounts(in: "Items 3, 450.00"), [450.00])
    }

    func testIgnoresDottedDatesAndReadsRupeePrefix() {
        XCTAssertEqual(ReceiptParser.amounts(in: "12.10.2025"), [])
        XCTAssertEqual(ReceiptParser.amounts(in: "Rs.450.00"), [450.00])
    }

    // MARK: Merchant

    func testMerchantIsFirstSensibleLine() {
        let lines = ["Receipt", "0112345678", "Java Lounge", "Colombo 03", "Total 900.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).merchant, "Java Lounge")
    }

    func testAllCapsMerchantIsCapitalized() {
        let lines = ["CARGILLS FOOD CITY", "TOTAL 1,250.00"]
        XCTAssertEqual(ReceiptParser.parse(lines: lines).merchant, "Cargills Food City")
    }

    func testNoMerchantInFirstFiveLines() {
        let lines = ["123", "456", "Tel 011", "www.shop.lk", "Invoice 7", "Late Shop Name"]
        XCTAssertNil(ReceiptParser.parse(lines: lines).merchant)
    }

    // MARK: Date

    func testFindsUnambiguousDate() throws {
        let lines = ["Shop", "Date: 12 Oct 2025", "Total 100.00"]
        let date = try XCTUnwrap(ReceiptParser.parse(lines: lines).date)
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(parts.year, 2025)
        XCTAssertEqual(parts.month, 10)
        XCTAssertEqual(parts.day, 12)
    }

    func testNumericDateIsReadDayFirst() throws {
        let lines = ["Shop", "05/10/2025 14:32", "Total 100.00"]
        let date = try XCTUnwrap(ReceiptParser.parse(lines: lines).date)
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(parts.day, 5)
        XCTAssertEqual(parts.month, 10)
        XCTAssertEqual(parts.year, 2025)
    }

    func testTwoDigitYear() throws {
        let lines = ["Shop", "Date: 17-03-25", "Total 100.00"]
        let date = try XCTUnwrap(ReceiptParser.parse(lines: lines).date)
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(parts.day, 17)
        XCTAssertEqual(parts.month, 3)
        XCTAssertEqual(parts.year, 2025)
    }

    func testIgnoresFutureDate() {
        let lines = ["Shop", "Valid until 12 Oct 2099", "Total 100.00"]
        XCTAssertNil(ReceiptParser.parse(lines: lines).date)
    }

    // MARK: Empty input

    func testEmptyInputReturnsAllNil() {
        XCTAssertEqual(ReceiptParser.parse(lines: []), ParsedReceipt())
        XCTAssertEqual(ReceiptParser.parse(lines: ["", "   "]), ParsedReceipt())
    }
}
