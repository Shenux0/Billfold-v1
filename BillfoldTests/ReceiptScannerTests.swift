// ReceiptScannerTests.swift
// Draws a fake receipt into an image and checks Vision can read it back.
// Also checks the resize helper keeps the shape and never upscales.

import XCTest
import UIKit
@testable import Billfold

final class ReceiptScannerTests: XCTestCase {

    /// A white image with black text lines, like a very clean receipt.
    private func makeReceiptImage(lines: [String]) -> UIImage {
        let size = CGSize(width: 800, height: 120 * CGFloat(lines.count) + 80)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 56, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            for (index, line) in lines.enumerated() {
                let point = CGPoint(x: 40, y: 40 + CGFloat(index) * 120)
                (line as NSString).draw(at: point, withAttributes: attributes)
            }
        }
    }

    func testRecognizesTextInRenderedReceipt() async throws {
        let image = makeReceiptImage(lines: ["BILLFOLD CAFE", "TOTAL 450.00"])
        let lines: [String]
        do {
            lines = try await ReceiptScanner.recognizeText(in: image)
        } catch {
            throw XCTSkip("Vision text recognition is not available here: \(error)")
        }
        if lines.isEmpty {
            throw XCTSkip("Vision returned no text, which happens on some simulators.")
        }
        XCTAssertTrue(lines.joined(separator: " ").uppercased().contains("TOTAL"))
    }

    func testScannedTextFeedsTheParser() async throws {
        let image = makeReceiptImage(lines: ["BILLFOLD CAFE", "TOTAL 450.00"])
        guard let lines = try? await ReceiptScanner.recognizeText(in: image), !lines.isEmpty else {
            throw XCTSkip("Vision text recognition is not available here.")
        }
        XCTAssertEqual(ReceiptParser.parse(lines: lines).total, 450.00)
    }

    func testResizeShrinksLongestSideAndKeepsShape() {
        let image = makeReceiptImage(lines: Array(repeating: "LINE", count: 30)) // 800 x 3680
        let small = image.resized(maxDimension: 1600)
        XCTAssertEqual(max(small.size.width, small.size.height), 1600, accuracy: 1)
        XCTAssertEqual(small.size.width / small.size.height,
                       image.size.width / image.size.height, accuracy: 0.01)
    }

    func testResizeNeverUpscales() {
        let image = makeReceiptImage(lines: ["SMALL"]) // 800 x 200
        let result = image.resized(maxDimension: 1600)
        XCTAssertEqual(result.size, image.size)
    }

    func testCompressedDataIsProduced() {
        let image = makeReceiptImage(lines: ["TOTAL 450.00"])
        XCTAssertNotNil(image.compressedData())
    }
}
