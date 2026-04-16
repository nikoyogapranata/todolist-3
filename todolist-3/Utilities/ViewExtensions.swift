//
//  ViewExtensions.swift
//  todolist-3
//
//  LAYER: Utilities
//  PURPOSE: Reusable SwiftUI helpers shared across multiple views.
//           Centralising extensions here avoids copy-paste across view files.
//

import SwiftUI

// -----------------------------------------------------------------------------
// PressActions – ViewModifier
// Gives any button/view a "press down" micro-animation by detecting the raw
// DragGesture state (started → pressed, ended → released). This provides a
// more responsive feel than ButtonStyle alone, especially for custom FABs.
//
// Usage:
//   myView.pressEvents(onPress: { isPressed = true },
//                      onRelease: { isPressed = false })
// -----------------------------------------------------------------------------
struct PressActions: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress()   }
                    .onEnded   { _ in onRelease() }
            )
    }
}

// Convenience extension so call sites read naturally:
//   .pressEvents(onPress: …, onRelease: …)
extension View {
    func pressEvents(onPress: @escaping () -> Void,
                     onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
