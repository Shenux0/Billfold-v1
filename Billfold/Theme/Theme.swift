// Theme.swift
// The app's few design constants in one place: the accent color and the
// card measurements. Changing a value here restyles every screen.

import SwiftUI
import UIKit

enum Theme {
    // Accent color with a light and a dark variant, so we need no asset catalog edits.
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.176, green: 0.831, blue: 0.659, alpha: 1)   // #2DD4A8
            : UIColor(red: 0.055, green: 0.624, blue: 0.510, alpha: 1)   // #0E9F82
    })

    static let cornerRadius: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 16
}
