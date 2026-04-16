//
//  ToDoViewModel.swift
//  todolist-3
//
//  LAYER: ViewModel
//  PURPOSE: The single source of truth for the app's state. Owns the task list,
//           user profile, theme, and filter state. All mutations go through here.
//           Tasks are now backed by Firebase Firestore (real-time sync).
//           Profile is persisted locally via UserDefaults.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

// =============================================================================
// MARK: - ToDoViewModel
// =============================================================================
class ToDoViewModel: ObservableObject {

    // ── Published State ───────────────────────────────────────────────────────

    /// The live task list, kept in sync with Firestore via a snapshot listener.
    @Published var tasks: [Task] = []

    /// Drives the search bar — views bind directly to this.
    @Published var searchText: String = ""

    /// Which subset of tasks is visible (all / active / completed).
    @Published var filterState: FilterState = .all

    /// User profile data (name, bio, avatar emoji).
    @Published var profile: UserProfile = UserProfile()

    // ── Theme (persisted locally via @AppStorage) ─────────────────────────────
    // Theme is intentionally NOT synced to Firestore — it's a per-device
    // preference, not shared data.
    @AppStorage("selectedTheme") private var storedTheme: String = Theme.dark.rawValue

    /// The active colour theme. Setting it persists the rawValue immediately.
    var currentTheme: Theme {
        get { Theme(rawValue: storedTheme) ?? .dark }
        set {
            storedTheme = newValue.rawValue
            objectWillChange.send()
        }
    }

    // ── Firestore ─────────────────────────────────────────────────────────────
    private var db = Firestore.firestore()

    /// Holds the active Firestore listener so we can remove it on deinit.
    private var listenerRegistration: ListenerRegistration?

    // ── Initialisation ────────────────────────────────────────────────────────

    init() {
        subscribeToTasks()
        loadProfile()
    }

    deinit {
        listenerRegistration?.remove()
    }

    // =========================================================================
    // MARK: - Firestore Real-Time Subscription
    // =========================================================================

    /// Attaches a Firestore snapshot listener that keeps `tasks` up to date in
    /// real time. Called once on init; safe to call again to reset the listener.
    func subscribeToTasks() {
        listenerRegistration?.remove()

        listenerRegistration = db.collection("tasks")
            .order(by: "createdAt", descending: true) // Newest first
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                guard let documents = querySnapshot?.documents else {
                    print("Firestore listener error: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                self.tasks = documents.compactMap { doc in
                    try? doc.data(as: Task.self)
                }
            }
    }

    // =========================================================================
    // MARK: - Computed Statistics (used by ProfileView & SettingsView)
    // =========================================================================

    var totalTaskCount: Int     { tasks.count }
    var activeTaskCount: Int    { tasks.filter { !$0.isCompleted }.count }
    var completedTaskCount: Int { tasks.filter {  $0.isCompleted }.count }
    var overdueTaskCount: Int   { tasks.filter {  $0.isOverdue   }.count }

    // =========================================================================
    // MARK: - Filtered Task List (used by TasksTab)
    // =========================================================================

    /// Returns the subset of tasks matching the current filter and search text.
    var filteredTasks: [Task] {
        let byFilter: [Task]
        switch filterState {
        case .all:       byFilter = tasks
        case .active:    byFilter = tasks.filter { !$0.isCompleted }
        case .completed: byFilter = tasks.filter {  $0.isCompleted }
        }

        guard !searchText.isEmpty else { return byFilter }
        return byFilter.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // =========================================================================
    // MARK: - Task CRUD (Firestore)
    // =========================================================================

    /// Creates a new task document in Firestore. The listener will pick it up
    /// and append it to `tasks` automatically — no manual array append needed.
    func addTask(
        title: String,
        description: String,
        priority: Priority,
        startDate: Date? = nil,
        deadline: Date? = nil
    ) {
        let newTask = Task(
            title: title,
            description: description,
            priority: priority,
            startDate: startDate,
            deadline: deadline
        )

        do {
            let _ = try db.collection("tasks").addDocument(from: newTask)
        } catch {
            print("Error adding task: \(error.localizedDescription)")
        }
    }

    /// Flips `isCompleted` for the given task in Firestore.
    func toggleCompletion(for task: Task) {
        guard let id = task.id else { return }
        db.collection("tasks").document(id).updateData([
            "isCompleted": !task.isCompleted
        ])
    }

    /// Overwrites an entire task document with the updated value.
    func updateTask(_ task: Task) {
        guard let id = task.id else { return }
        do {
            try db.collection("tasks").document(id).setData(from: task)
        } catch {
            print("Error updating task: \(error.localizedDescription)")
        }
    }

    /// Deletes the Firestore document for the given task ID.
    func deleteTask(withID id: String?) {
        guard let id = id else { return }
        db.collection("tasks").document(id).delete()
    }

    /// Deletes all tasks where `isCompleted == true` from Firestore.
    func clearCompletedTasks() {
        let completed = tasks.filter { $0.isCompleted }
        for task in completed {
            deleteTask(withID: task.id)
        }
    }

    /// Deletes ALL tasks and resets the profile. Use with caution.
    func deleteAllTasks() {
        for task in tasks {
            deleteTask(withID: task.id)
        }
    }

    // No-op kept for API compatibility with SettingsView — data persistence is
    // handled by Firestore automatically.
    func saveTasks() { /* Firestore handles persistence automatically */ }

    // =========================================================================
    // MARK: - Subtask Operations
    // =========================================================================

    /// Appends a new subtask to the task document identified by `taskID`.
    func addSubTask(to taskID: String, title: String) {
        guard let task = tasks.first(where: { $0.id == taskID }) else { return }
        var updated = task
        updated.subtasks.append(SubTask(title: title))
        updateTask(updated)
    }

    /// Toggles the `isCompleted` flag of the subtask identified by `subID`
    /// within the parent task identified by `taskID`.
    func toggleSubTask(taskID: String, subID: String) {
        guard var task = tasks.first(where: { $0.id == taskID }),
              let idx  = task.subtasks.firstIndex(where: { $0.id == subID })
        else { return }

        task.subtasks[idx].isCompleted.toggle()
        updateTask(task)
    }

    /// Removes subtasks at the given index offsets from the parent task.
    func deleteSubTasks(taskID: String, at offsets: IndexSet) {
        guard var task = tasks.first(where: { $0.id == taskID }) else { return }
        task.subtasks.remove(atOffsets: offsets)
        updateTask(task)
    }

    // =========================================================================
    // MARK: - Profile (UserDefaults — local per-device)
    // =========================================================================

    private let profileKey = "userProfile_v1"

    /// Loads the user profile from UserDefaults, falling back to defaults.
    func loadProfile() {
        guard
            let data    = UserDefaults.standard.data(forKey: profileKey),
            let decoded = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return }

        profile = decoded
    }

    /// Encodes and saves the current profile to UserDefaults.
    func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
}
