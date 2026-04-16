//
//  Task.swift
//  todolist-3
//
//  LAYER: Model
//  PURPOSE: Defines the Task data structure. This is a pure value type (struct)
//           with no UI or business-logic dependencies — it only holds data.
//           Codable enables JSON serialisation into UserDefaults for persistence.
//

import Foundation
import FirebaseFirestoreSwift// Required for @DocumentID
import FirebaseFirestore

// -----------------------------------------------------------------------------
// Task
// A value type (struct) that represents a single to-do item.
//
// Identifiable → SwiftUI List can track each row by id (no need for index math).
// Codable       → JSONEncoder/JSONDecoder can save/load the whole array with one
//                 call; no manual dictionary mapping required.
// -----------------------------------------------------------------------------
struct Task: Identifiable, Codable {

    /// Unique identifier – auto-generated on creation, never changes.
    @DocumentID var id: String? // Firestore will auto-fill this

    /// Short headline shown in the task row.
    var title: String

    /// Optional longer description with additional context.
    var description: String

    /// Urgency level – drives badge colour and sorting.
    var priority: Priority

    /// Whether the task has been finished. Toggled by the user.
    var isCompleted: Bool = false

    /// Creation timestamp used for default descending sort order.
    var createdAt: Date = Date()

    /// Optional date when work on the task should begin.
    var startDate: Date? = nil

    /// Optional deadline; the row card shows a warning chip when approaching.
    var deadline: Date? = nil

    /// Ordered list of child to-do items nested under this task.
    var subtasks: [SubTask] = []

    // ── Computed Helpers ──────────────────────────────────────────────────────

    /// Number of completed subtasks.
    var completedSubtaskCount: Int { subtasks.filter { $0.isCompleted }.count }

    /// Progress from 0.0 to 1.0 based on completed subtasks.
    /// Returns nil when there are no subtasks so callers can skip the bar.
    var subtaskProgress: Double? {
        guard !subtasks.isEmpty else { return nil }
        return Double(completedSubtaskCount) / Double(subtasks.count)
    }

    /// True if the deadline has already passed and the task is not completed.
    var isOverdue: Bool {
        guard let dl = deadline, !isCompleted else { return false }
        return dl < Date()
    }

    /// True if the deadline is within the next 24 hours and the task is not yet done.
    var isDueSoon: Bool {
        guard let dl = deadline, !isCompleted, !isOverdue else { return false }
        return dl.timeIntervalSinceNow < 86_400
    }
}
