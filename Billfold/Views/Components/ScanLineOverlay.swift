// ScanLineOverlay.swift
// The custom "scanning" animation: a glowing line that sweeps up and down
// over the receipt photo while Vision reads it.

import SwiftUI

struct ScanLineOverlay: View {
    @State private var atBottom = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let lineHeight: CGFloat = 10

    var body: some View {
        // GeometryReader tells us how tall the photo is, so the line knows how far to travel.
        GeometryReader { geometry in
            Capsule()
                .fill(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: lineHeight)
                .padding(.horizontal, 8)
                .offset(y: atBottom ? geometry.size.height - lineHeight : 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            // People who turn on Reduce Motion see a still line instead of a moving one.
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                atBottom = true
            }
        }
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 20)
        .fill(.gray.opacity(0.2))
        .frame(width: 240, height: 320)
        .overlay { ScanLineOverlay() }
}
