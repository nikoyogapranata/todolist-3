//
//  ThemeSelectorView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: A horizontally scrolling panel of colour swatches that lets the
//           user pick the app's visual theme. Slides in/out from the top of
//           ContentView when the palette toolbar button is tapped.
//
//  DATA FLOW:
//    (DOWN/UP) currentTheme → @Binding into ToDoViewModel.currentTheme
//              Tapping a swatch writes the new theme back via the Binding;
//              ToDoViewModel propagates it to @AppStorage automatically.
//

import SwiftUI

// -----------------------------------------------------------------------------
// ThemeSelectorView
// Composed from ThemeSwatchButton components (one per Theme case).
// -----------------------------------------------------------------------------
struct ThemeSelectorView: View {
    @Binding var currentTheme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Section header label
            Text("THEME")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(currentTheme.secondaryLabelColor)
                .padding(.horizontal, 20)

            // Horizontally scrollable swatch row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Theme.allCases) { theme in
                        ThemeSwatchButton(
                            theme: theme,
                            isSelected: currentTheme == theme
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                // Writing to the Binding propagates change up
                                // to ToDoViewModel → @AppStorage → persisted.
                                currentTheme = theme
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Preview
struct ThemeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSelectorView(currentTheme: .constant(.dark))
            .background(Color.black)
    }
}
