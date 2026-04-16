//
//  EmptyStateView.swift
//  todolist-3
//
//  LAYER: View / Component
//  PURPOSE: Friendly placeholder shown when no tasks match the active
//           filter or search query. Receives theme and filterState as
//           plain value parameters — no ViewModel dependency needed.
//

import SwiftUI

// -----------------------------------------------------------------------------
// EmptyStateView
// A purely presentational component.
//
// Data flow (DOWN only):
//   ContentView passes `theme` and `filterState` as plain values.
//   This view never writes back — it only renders.
// -----------------------------------------------------------------------------
struct EmptyStateView: View {
    let theme: Theme
    let filterState: FilterState

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: emptyIcon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(theme.accentColor.opacity(0.55))

            Text(emptyTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(theme.labelColor)

            Text(emptySubtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(theme.secondaryLabelColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    private var emptyIcon: String {
        switch filterState {
        case .all:       return "checklist"
        case .active:    return "sparkles"
        case .completed: return "medal.fill"
        }
    }

    private var emptyTitle: String {
        switch filterState {
        case .all:       return "No Tasks Yet"
        case .active:    return "All Done!"
        case .completed: return "Nothing Completed"
        }
    }

    private var emptySubtitle: String {
        switch filterState {
        case .all:       return "Tap the + button to add your first task."
        case .active:    return "You've completed everything — great work!"
        case .completed: return "Complete a task to see it here."
        }
    }
}

// MARK: - Preview
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(theme: .dark, filterState: .all)
            .background(Color.black)
    }
}
