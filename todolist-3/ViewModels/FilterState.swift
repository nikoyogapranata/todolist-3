//
//  FilterState.swift
//  todolist-3
//
//  LAYER: ViewModel support
//  PURPOSE: Defines the filter options for the task list.
//           Kept separate so it can be used in both ToDoViewModel and
//           FilterBarView without creating a dependency between them.
//

import Foundation

// -----------------------------------------------------------------------------
// FilterState
// Controls which subset of tasks the user sees:
//   • .all       – every task regardless of completion
//   • .active    – only tasks where isCompleted == false
//   • .completed – only tasks where isCompleted == true
// -----------------------------------------------------------------------------
enum FilterState: String, CaseIterable, Identifiable {
    case all       = "All"
    case active    = "Active"
    case completed = "Completed"

    /// Required by Identifiable – rawValue is unique per case.
    var id: String { rawValue }
}
