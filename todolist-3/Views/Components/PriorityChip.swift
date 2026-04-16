//
//  PriorityChip.swift
//  todolist-3
//
//  LAYER: View / Component
//  PURPOSE: A small rounded-rectangle chip used in AddTaskView's priority
//           picker row. Self-contained so it can be reused anywhere a
//           priority selection UI is needed.
//

import SwiftUI

// -----------------------------------------------------------------------------
// PriorityChip
// Data flow (DOWN): receives the Priority value, selected state, and action.
// Data flow (UP):   calls `action` closure on tap; the parent owns the
//                   @State for which priority is selected.
// -----------------------------------------------------------------------------
struct PriorityChip: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: priority.icon)
                Text(priority.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(isSelected ? priority.color : priority.color.opacity(0.15))
            .foregroundColor(isSelected ? .white : priority.color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(priority.color.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct PriorityChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            PriorityChip(priority: .low,    isSelected: false) {}
            PriorityChip(priority: .medium, isSelected: true)  {}
            PriorityChip(priority: .high,   isSelected: false) {}
        }
        .padding()
        .background(Color.black)
    }
}
