//
//  FloatingAddButton.swift
//  todolist-3
//
//  LAYER: View / Component
//  PURPOSE: The circular Floating Action Button (FAB) fixed to the bottom-right
//           corner of ContentView. Encapsulated here so ContentView's body
//           stays clean. Uses the PressActions utility for a spring press effect.
//

import SwiftUI

// -----------------------------------------------------------------------------
// FloatingAddButton
// Data flow (DOWN): receives accentColor from parent's theme.
// Data flow (UP):   calls `action` closure when tapped — the parent decides
//                   what happens (showing the AddTask sheet).
// -----------------------------------------------------------------------------
struct FloatingAddButton: View {
    let accentColor: Color
    let action: () -> Void

    /// Drives the scale-down spring animation on press.
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 62, height: 62)
                .background(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: accentColor.opacity(0.55), radius: 16, y: 8)
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        // Attach press-down spring animation using the Utilities extension
        .pressEvents {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Preview
struct FloatingAddButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            FloatingAddButton(accentColor: .blue) {}
        }
    }
}
