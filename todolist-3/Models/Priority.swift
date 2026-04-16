//
//  Priority.swift
//  todolist-3
//
//  LAYER: Model
//  PURPOSE: Defines the Priority enum that represents a task's urgency level.
//           Kept in its own file so it can be imported / tested independently.
//

import SwiftUI

// -----------------------------------------------------------------------------
// Priority
// A Codable enum so values survive JSON encode/decode (UserDefaults persistence).
// CaseIterable lets us loop over all cases in pickers without hard-coding them.
// Identifiable (id = rawValue) allows direct use inside SwiftUI ForEach loops.
// -----------------------------------------------------------------------------
enum Priority: String, CaseIterable, Codable, Identifiable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"

    /// Required by Identifiable – the rawValue String is unique per case.
    var id: String { rawValue }

    // ── Display Helpers ───────────────────────────────────────────────────────

    /// SF Symbol name that visually communicates the urgency level.
    var icon: String {
        switch self {
        case .low:    return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high:   return "arrow.up.circle.fill"
        }
    }

    /// Colour associated with each priority so badges are instantly readable.
    var color: Color {
        switch self {
        case .low:    return Color(hue: 0.38, saturation: 0.70, brightness: 0.75) // green
        case .medium: return Color(hue: 0.11, saturation: 0.85, brightness: 0.95) // amber
        case .high:   return Color(hue: 0.01, saturation: 0.80, brightness: 0.88) // red-orange
        }
    }
}
