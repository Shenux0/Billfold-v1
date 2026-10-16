// ReceiptScanner.swift
// Reads the text on a receipt photo with Apple's Vision framework.
// Everything happens on the device; the photo is never uploaded.

import Vision
import UIKit

enum ReceiptScanner {
    enum ScanError: Error {
        case noImage
    }

    /// Reads all text lines in the image, top to bottom, fully on the device.
    /// Resize the image first (see UIImage+Resize) so it is upright and not too large.
    nonisolated static func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw ScanError.noImage }
        // Vision is synchronous and heavy, so run it off the main thread.
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let observations = request.results ?? []
            return observations.compactMap { $0.topCandidates(1).first?.string }
        }.value
    }
}
