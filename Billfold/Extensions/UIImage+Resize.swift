// UIImage+Resize.swift
// Shrinks receipt photos before OCR and saving. Smaller images use less memory,
// make Vision faster, and redrawing fixes the photo's rotation for us.

import UIKit

extension UIImage {
    /// Scales the image so its longest side is at most `maxDimension` pixels.
    /// Never makes an image bigger. Redrawing bakes the orientation into the pixels,
    /// so Vision reads portrait phone photos the right way up.
    /// `nonisolated` because the scan flow calls this from a background task.
    nonisolated func resized(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        let ratio = longestSide > maxDimension ? maxDimension / longestSide : 1
        let newSize = CGSize(width: (size.width * ratio).rounded(),
                             height: (size.height * ratio).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // work in real pixels, not screen points
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// JPEG at 60% quality: much smaller on disk and still easy to read.
    nonisolated func compressedData() -> Data? {
        jpegData(compressionQuality: 0.6)
    }
}
