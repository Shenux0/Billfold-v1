// ScanViewModel.swift
// Runs the scan flow step by step: load photo -> shrink -> read text -> parse.
// It is the only view model because this is the only screen with async, multi-step state.

import SwiftUI
import PhotosUI
import Observation

enum ScanState: Equatable {
    case idle
    case processing
    case result(ParsedReceipt)
    case failed(String)
}

@MainActor @Observable
final class ScanViewModel {
    private(set) var state: ScanState = .idle
    private(set) var image: UIImage?
    private(set) var imageData: Data?

    /// A form draft built from the scan result, or nil if there is no result yet.
    var draft: ExpenseDraft? {
        guard case .result(let parsed) = state else { return nil }
        return ExpenseDraft(parsed: parsed, imageData: imageData)
    }

    /// Loads the photo the user picked. PhotosPicker hands us raw data, not an image.
    func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        state = .processing
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else {
                state = .failed("That photo could not be opened. Please choose another one.")
                return
            }
            await process(picked)
        } catch {
            state = .failed("That photo could not be opened. Please choose another one.")
        }
    }

    /// Shrinks the photo, reads its text with Vision and parses the result.
    func process(_ original: UIImage) async {
        state = .processing
        // Resizing a 12 MP photo takes a moment, so do it off the main thread too.
        // MAC-CHECK: if Xcode warns that UIImage is not Sendable here, the warning is safe to ignore.
        let prepared = await Task.detached(priority: .userInitiated) {
            let small = original.resized(maxDimension: 1600)
            return (small, small.compressedData())
        }.value
        image = prepared.0
        imageData = prepared.1

        do {
            let lines = try await ReceiptScanner.recognizeText(in: prepared.0)
            #if DEBUG
            // Shows in Xcode's console exactly what Vision read, to see why a receipt parsed wrongly.
            print("Billfold OCR lines:\n" + lines.joined(separator: "\n"))
            #endif
            if lines.isEmpty {
                state = .failed("No text was found. Try a sharper, well-lit photo of the receipt.")
            } else {
                state = .result(ReceiptParser.parse(lines: lines))
            }
        } catch {
            state = .failed("The receipt could not be read. Please try another photo.")
        }
    }

    func reset() {
        state = .idle
        image = nil
        imageData = nil
    }
}
