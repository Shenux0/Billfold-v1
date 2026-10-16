// CardStyle.swift
// A custom ViewModifier that gives any view the app's card look.
// Written once here, then used everywhere as `.card()`.

import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            // A system color, so the card looks right in both Light and Dark Mode.
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

extension View {
    func card() -> some View {
        modifier(CardStyle())
    }
}
