//
//  SubTask.swift
//  todolist-3
//
//  LAYER: Model
//  PURPOSE: Represents a child to-do item nested inside a parent Task.
//           Kept as a separate Codable struct so it can be serialised
//           as part of the parent Task's Firestore document automatically.
//           The id is stored as a String (UUID string) for Firestore compatibility.
//

import Foundation

// -----------------------------------------------------------------------------
// SubTask
// A lightweight value type that lives inside Task.subtasks.
// Identifiable  → SwiftUI ForEach can track each row by id.
// Codable       → Encoded/decoded automatically alongside its parent Task.
// The id is a String (not UUID) so Firestore can serialise it without issues.
// -----------------------------------------------------------------------------
struct SubTask: Identifiable, Codable {

    /// Unique identifier – generated once, never changes. Stored as String for Firestore.
    var id: String = UUID().uuidString

    /// Short description of this sub-item.
    var title: String

    /// Toggled when the user ticks off this child task.
    var isCompleted: Bool = false

    /// Creation timestamp for stable sort order.
    var createdAt: Date = Date()
}
