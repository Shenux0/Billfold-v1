// CurrencyDetectorTests.swift
// Checks that receipts showing "$", "Rs" or a written currency code are
// detected correctly, and that receipts with no currency return nil.

import XCTest
@testable import Billfold

final class CurrencyDetectorTests: XCTestCase {

    func testDollarSignMeansUSD() {
        XCTAssertEqual(CurrencyDetector.detect(in: ["CORNER CAFE", "TOTAL $12.50"]), "USD")
    }

    func testRupeesPrefixMeansLKR() {
        XCTAssertEqual(CurrencyDetector.detect(in: ["KEELLS SUPER", "TOTAL Rs. 1,250.00"]), "LKR")
        XCTAssertEqual(CurrencyDetector.detect(in: ["NET AMOUNT RS 950.00"]), "LKR")
    }

    func testWrittenCodeWins() {
        XCTAssertEqual(CurrencyDetector.detect(in: ["Amount Due (USD)", "45.00"]), "USD")
        XCTAssertEqual(CurrencyDetector.detect(in: ["Total LKR 3,400.00"]), "LKR")
        XCTAssertEqual(CurrencyDetector.detect(in: ["Total 20.00 EUR"]), "EUR")
    }

    func testCodeInsideAWordIsIgnored() {
        // "Mrs" contains "rs" and "USDA" contains "USD", but neither is a currency.
        XCTAssertNil(CurrencyDetector.detect(in: ["Mrs Perera", "USDA Organic"]))
    }

    func testNoCurrencyGivesNil() {
        XCTAssertNil(CurrencyDetector.detect(in: ["Shop", "TOTAL 1,250.00"]))
        XCTAssertNil(CurrencyDetector.detect(in: []))
    }

    func testParserPassesCurrencyThrough() {
        let parsed = ReceiptParser.parse(lines: ["CORNER CAFE", "TOTAL $12.50"])
        XCTAssertEqual(parsed.currencyCode, "USD")
        XCTAssertEqual(parsed.total, 12.50)
    }
}
