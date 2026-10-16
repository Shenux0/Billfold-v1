// CategoryGuesserTests.swift
// Checks that well-known merchants land in the right category and that
// anything unknown falls back to Other.

import XCTest
@testable import Billfold

final class CategoryGuesserTests: XCTestCase {

    func testKnownMerchantsMapToCategories() {
        XCTAssertEqual(CategoryGuesser.guess(from: "Keells Super"), .food)
        XCTAssertEqual(CategoryGuesser.guess(from: "Java Coffee House"), .food)
        XCTAssertEqual(CategoryGuesser.guess(from: "PickMe Ride"), .transport)
        XCTAssertEqual(CategoryGuesser.guess(from: "Ceypetco Fuel Station"), .transport)
        XCTAssertEqual(CategoryGuesser.guess(from: "Union Chemists Pharmacy"), .health)
        XCTAssertEqual(CategoryGuesser.guess(from: "Dialog Axiata"), .bills)
        XCTAssertEqual(CategoryGuesser.guess(from: "ODEL"), .shopping)
        XCTAssertEqual(CategoryGuesser.guess(from: "Scope Cinemas"), .entertainment)
    }

    func testMatchingIgnoresCase() {
        XCTAssertEqual(CategoryGuesser.guess(from: "CARGILLS FOOD CITY"), .food)
    }

    func testUnknownMerchantIsOther() {
        XCTAssertEqual(CategoryGuesser.guess(from: "Kamal Hardware"), .other)
        XCTAssertEqual(CategoryGuesser.guess(from: ""), .other)
    }

    func testNilMerchantIsOther() {
        XCTAssertEqual(CategoryGuesser.guess(from: nil), .other)
    }
}
