// CategoryBadge.swift
// The small colored square with a category icon. Used in rows, the form's
// category picker and the Insights list so categories always look the same.

import SwiftUI

struct CategoryBadge: View {
    let category: ExpenseCategory
    var isSelected = false

    // Grows with the user's text size setting (Dynamic Type).
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 40

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)

        Image(systemName: category.symbol)
            .font(.body)
            .foregroundStyle(category.color)
            .frame(width: size, height: size)
            .background(category.color.opacity(0.2), in: shape)
            .overlay {
                if isSelected {
                    shape.strokeBorder(category.color, lineWidth: 2)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            .accessibilityLabel(category.title)
    }
}

#Preview {
    HStack {
        CategoryBadge(category: .food)
        CategoryBadge(category: .transport, isSelected: true)
        CategoryBadge(category: .health)
    }
}
