//
//  Theme.swift
//  todolist-3
//
//  LAYER: Model
//  PURPOSE: Defines the six visual themes available in the app. Each theme
//           owns its complete colour palette through computed properties so
//           every view just reads from the theme — no colour literals scattered
//           across the codebase.
//

import SwiftUI

// -----------------------------------------------------------------------------
// Theme
// The raw String value is persisted via @AppStorage (ToDoViewModel) so the
// user's choice survives app restarts. CaseIterable enables the theme picker
// to loop all options automatically.
// -----------------------------------------------------------------------------
enum Theme: String, CaseIterable, Identifiable {
    case light         = "Light"
    case dark          = "Dark"
    case midnight      = "Midnight"
    case astral        = "Astral"
    case cherryBlossom = "Cherry Blossom"
    case autumn        = "Autumn"

    /// Required by Identifiable – rawValue is unique per case.
    var id: String { rawValue }

    // ── Background Gradient ───────────────────────────────────────────────────
    /// Two-stop gradient drawn behind the entire app chrome.
    var backgroundColors: [Color] {
        switch self {
        case .light:
            return [Color(hue: 0.60, saturation: 0.05, brightness: 0.97),
                    Color(hue: 0.60, saturation: 0.10, brightness: 0.93)]
        case .dark:
            return [Color(hue: 0.00, saturation: 0.00, brightness: 0.12),
                    Color(hue: 0.00, saturation: 0.00, brightness: 0.08)]
        case .midnight:
            return [Color(hue: 0.67, saturation: 0.55, brightness: 0.18),
                    Color(hue: 0.67, saturation: 0.70, brightness: 0.08)]
        case .astral:
            return [Color(hue: 0.72, saturation: 0.65, brightness: 0.22),
                    Color(hue: 0.58, saturation: 0.75, brightness: 0.14)]
        case .cherryBlossom:
            return [Color(hue: 0.94, saturation: 0.18, brightness: 0.98),
                    Color(hue: 0.94, saturation: 0.30, brightness: 0.93)]
        case .autumn:
            return [Color(hue: 0.08, saturation: 0.25, brightness: 0.96),
                    Color(hue: 0.07, saturation: 0.40, brightness: 0.90)]
        }
    }

    // ── Accent Colour ─────────────────────────────────────────────────────────
    /// Primary interactive colour: buttons, toggles, highlights, FAB shadow.
    var accentColor: Color {
        switch self {
        case .light:         return Color(hue: 0.60, saturation: 0.75, brightness: 0.70)
        case .dark:          return Color(hue: 0.58, saturation: 0.60, brightness: 0.90)
        case .midnight:      return Color(hue: 0.67, saturation: 0.50, brightness: 0.90)
        case .astral:        return Color(hue: 0.54, saturation: 0.70, brightness: 0.95)
        case .cherryBlossom: return Color(hue: 0.94, saturation: 0.65, brightness: 0.80)
        case .autumn:        return Color(hue: 0.06, saturation: 0.85, brightness: 0.80)
        }
    }

    // ── Card / Row Surface ────────────────────────────────────────────────────
    /// Background colour for individual task cards.
    var cardSurface: Color {
        switch self {
        case .light:         return Color.white.opacity(0.85)
        case .dark:          return Color(white: 0.15).opacity(0.90)
        case .midnight:      return Color(hue: 0.67, saturation: 0.40, brightness: 0.22).opacity(0.90)
        case .astral:        return Color(hue: 0.70, saturation: 0.40, brightness: 0.28).opacity(0.90)
        case .cherryBlossom: return Color(hue: 0.94, saturation: 0.10, brightness: 1.00).opacity(0.88)
        case .autumn:        return Color(hue: 0.08, saturation: 0.12, brightness: 0.99).opacity(0.88)
        }
    }

    // ── Primary Label Colour ──────────────────────────────────────────────────
    var labelColor: Color {
        switch self {
        case .light, .cherryBlossom, .autumn:
            return Color(white: 0.15)
        case .dark, .midnight, .astral:
            return Color.white
        }
    }

    // ── Secondary Label Colour ────────────────────────────────────────────────
    var secondaryLabelColor: Color {
        labelColor.opacity(0.55)
    }

    // ── Swatch Colour (Theme Picker Circle) ───────────────────────────────────
    /// Representative colour shown in ThemeSelectorView.
    var swatch: Color { accentColor }
}
