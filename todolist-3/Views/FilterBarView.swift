//
//  FilterBarView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: A horizontally-laid-out row of animated capsule buttons that
//           lets the user switch between All / Active / Completed views.
//
//  DATA FLOW:
//    (DOWN) theme       → plain value, drives colours
//    (DOWN/UP) filterState → @Binding, taps HERE are reflected in ViewModel
//

import SwiftUI

// -----------------------------------------------------------------------------
// FilterBarView
// Receives filterState as a @Binding so that selection changes are written
// directly back to ToDoViewModel without needing a closure callback.
// -----------------------------------------------------------------------------
struct FilterBarView: View {
    @Binding var filterState: FilterState
    let theme: Theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FilterState.allCases) { state in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        filterState = state
                    }
                } label: {
                    Text(state.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .background(
                            filterState == state
                                ? theme.accentColor
                                : theme.cardSurface
                        )
                        .foregroundColor(
                            filterState == state
                                ? .white
                                : theme.labelColor
                        )
                        .clipShape(Capsule())
                        .shadow(
                            color: filterState == state
                                ? theme.accentColor.opacity(0.45) : .clear,
                            radius: 8, y: 4
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(filterState == state ? 1.04 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: filterState)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct FilterBarView_Previews: PreviewProvider {
    static var previews: some View {
        FilterBarView(filterState: .constant(.all), theme: .dark)
            .background(Color.black)
    }
}
