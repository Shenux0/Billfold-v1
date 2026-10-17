// ReceiptScanner.swift
// Reads the text on a receipt photo with Apple's Vision framework.
// Everything happens on the device; the photo is never uploaded.

import Vision
import UIKit

enum ReceiptScanner {
    enum ScanError: Error {
        case noImage
    }

    /// One piece of text Vision found, with its position on the image.
    /// Vision positions run from 0 to 1, with y = 0 at the BOTTOM of the image.
    struct TextPiece {
        let text: String
        let box: CGRect
    }

    /// Reads all text lines in the image, top to bottom, fully on the device.
    /// Resize the image first (see UIImage+Resize) so it is upright and not too large.
    nonisolated static func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw ScanError.noImage }
        // Vision is synchronous and heavy, so run it off the main thread.
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            // Correction "fixes" shop names into dictionary words, which hurts more than it helps here.
            request.usesLanguageCorrection = false
            // The default skips text smaller than 1/32 of the image height, which is most of a receipt.
            request.minimumTextHeight = 0.005
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let pieces = (request.results ?? []).compactMap { observation -> TextPiece? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return TextPiece(text: text, box: observation.boundingBox)
            }
            return buildLines(from: pieces)
        }.value
    }

    /// Vision returns separate pieces, so "TOTAL" and "1,250.00" on the same printed line
    /// arrive as two pieces, often far apart in the list. This puts pieces at the same
    /// height back together into one line, then orders the lines top to bottom.
    nonisolated static func buildLines(from pieces: [TextPiece]) -> [String] {
        let topToBottom = pieces.sorted { $0.box.midY > $1.box.midY }
        var rows: [[TextPiece]] = []

        for piece in topToBottom {
            if let last = rows.last?.last,
               abs(last.box.midY - piece.box.midY) < min(last.box.height, piece.box.height) * 0.6 {
                rows[rows.count - 1].append(piece)
            } else {
                rows.append([piece])
            }
        }

        return rows.map { row in
            row.sorted { $0.box.minX < $1.box.minX }
                .map(\.text)
                .joined(separator: " ")
        }
    }
}
