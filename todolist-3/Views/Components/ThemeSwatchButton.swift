//
//  ThemeSwatchButton.swift
//  todolist-3
//
//  LAYER: View / Component
//  PURPOSE: A single circular colour swatch with a label used inside
//           ThemeSelectorView. Extracted so ThemeSelectorView stays clean.
//

import SwiftUI

// -----------------------------------------------------------------------------
// ThemeSwatchButton
// Data flow (DOWN): receives the Theme to represent, whether it is selected,
//                   and an `action` closure.
// Data flow (UP):   calls `action` on tap; ThemeSelectorView owns the Binding.
// -----------------------------------------------------------------------------
struct ThemeSwatchButton: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Outer ring – visible only when this theme is active
                    Circle()
                        .strokeBorder(isSelected ? theme.swatch : Color.clear, lineWidth: 3)
                        .frame(width: 48, height: 48)

                    // Filled swatch circle
                    Circle()
                        .fill(theme.swatch)
                        .frame(width: 38, height: 38)
                        .shadow(color: theme.swatch.opacity(0.50), radius: 6, y: 3)

                    // Checkmark overlay when selected
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)

                // Theme name label below the circle
                Text(theme.rawValue)
                    .font(.system(size: 10,
                                  weight: isSelected ? .bold : .regular,
                                  design: .rounded))
                    .foregroundColor(isSelected ? theme.swatch : theme.secondaryLabelColor)
                    .lineLimit(1)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct ThemeSwatchButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            ThemeSwatchButton(theme: .dark,   isSelected: true)  {}
            ThemeSwatchButton(theme: .astral, isSelected: false) {}
        }
        .padding()
        .background(Color.black)
    }
}
