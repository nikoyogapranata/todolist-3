//
//  TaskDetailView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: Shows the full details of a single task with inline editing,
//           subtask management, and delete functionality. Reads the live
//           task from the ViewModel so Firestore updates are reflected
//           automatically without manual refreshing.
//

import SwiftUI

struct TaskDetailView: View {
    @ObservedObject var viewModel: ToDoViewModel
    let task: Task

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing: Bool = false

    // ── Edit Draft State ──────────────────────────────────────────────────────
    @State private var draftTitle: String         = ""
    @State private var draftDesc: String          = ""
    @State private var draftPriority: Priority    = .medium
    @State private var draftEnableStart: Bool     = false
    @State private var draftStartDate: Date       = Date()
    @State private var draftEnableDeadline: Bool  = false
    @State private var draftDeadline: Date        = Date()

    // ── Subtask State ─────────────────────────────────────────────────────────
    @State private var newSubtaskTitle: String    = ""
    @State private var showSubtaskField: Bool     = false

    // ── Delete Confirmation ───────────────────────────────────────────────────
    @State private var showDeleteConfirm: Bool    = false

    private var theme: Theme { viewModel.currentTheme }

    /// Always reads the freshest version of this task from the ViewModel
    /// so that Firestore updates (like subtask changes) appear in real time.
    private var liveTask: Task {
        viewModel.tasks.first(where: { $0.id == task.id }) ?? task
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    descriptionCard
                    datesCard
                    subtasksCard
                    dangerCard
                    Spacer(minLength: 30)
                }
                .padding(16)
            }
        }
        .navigationTitle(isEditing ? "Edit Task" : "Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { commitEdits() } else { beginEditing() }
                }
                .foregroundColor(theme.accentColor)
            }
        }
        .confirmationDialog("Delete Task?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Task", role: .destructive) {
                viewModel.deleteTask(withID: liveTask.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear { populateDraft() }
    }

    // MARK: - Header Card (title + completion toggle + priority)

    private var headerCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                // Completion toggle
                Button {
                    viewModel.toggleCompletion(for: liveTask)
                } label: {
                    Image(systemName: liveTask.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30))
                        .foregroundColor(liveTask.isCompleted ? theme.accentColor : theme.secondaryLabelColor)
                }
                .buttonStyle(.plain)

                // Title (tappable to edit when in editing mode)
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("Title", text: $draftTitle)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(theme.labelColor)
                    } else {
                        Text(liveTask.title)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(theme.labelColor)
                            .strikethrough(liveTask.isCompleted, color: theme.secondaryLabelColor)
                            .opacity(liveTask.isCompleted ? 0.55 : 1.0)
                    }
                }

                Spacer()

                // Priority badge
                if isEditing {
                    Menu {
                        ForEach(Priority.allCases) { p in
                            Button {
                                draftPriority = p
                            } label: {
                                Label(p.rawValue, systemImage: p.icon)
                            }
                        }
                    } label: {
                        Image(systemName: draftPriority.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(draftPriority.color)
                    }
                } else {
                    Image(systemName: liveTask.priority.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(liveTask.priority.color)
                        .opacity(liveTask.isCompleted ? 0.35 : 1.0)
                }
            }
        }
        .padding(16)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("NOTES", systemImage: "text.alignleft")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)

            if isEditing {
                TextField("Add notes…", text: $draftDesc, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(theme.labelColor)
            } else {
                if liveTask.description.isEmpty {
                    Text("No notes added.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(theme.secondaryLabelColor)
                        .italic()
                } else {
                    Text(liveTask.description)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(theme.labelColor)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    // MARK: - Dates Card

    private var datesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("DATES", systemImage: "calendar")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)

            if isEditing {
                // Start date toggle
                Toggle(isOn: $draftEnableStart) {
                    Label("Start Date", systemImage: "play.circle")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(theme.labelColor)
                }
                .tint(theme.accentColor)

                if draftEnableStart {
                    DatePicker("", selection: $draftStartDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .tint(theme.accentColor)
                }

                Divider().background(theme.secondaryLabelColor.opacity(0.2))

                // Deadline toggle
                Toggle(isOn: $draftEnableDeadline) {
                    Label("Deadline", systemImage: "calendar.badge.exclamationmark")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(theme.labelColor)
                }
                .tint(theme.accentColor)

                if draftEnableDeadline {
                    DatePicker("", selection: $draftDeadline, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .tint(theme.accentColor)
                }
            } else {
                // Read-only date display
                if let start = liveTask.startDate {
                    dateRow(icon: "play.circle.fill", label: "Start", value: dateFormatter.string(from: start), color: theme.accentColor)
                }

                if let deadline = liveTask.deadline {
                    let color: Color = liveTask.isOverdue ? .red : (liveTask.isDueSoon ? .orange : theme.secondaryLabelColor)
                    dateRow(icon: "calendar.badge.exclamationmark", label: "Deadline", value: dateFormatter.string(from: deadline), color: color)
                }

                if liveTask.startDate == nil && liveTask.deadline == nil {
                    Text("No dates set.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(theme.secondaryLabelColor)
                        .italic()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    @ViewBuilder
    private func dateRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 15))
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(color)
        }
    }

    // MARK: - Subtasks Card

    private var subtasksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Label("SUBTASKS", systemImage: "list.bullet.indent")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(theme.secondaryLabelColor)
                Spacer()
                Text("\(liveTask.completedSubtaskCount)/\(liveTask.subtasks.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.secondaryLabelColor)
            }

            // Subtask rows
            if liveTask.subtasks.isEmpty && !showSubtaskField {
                Text("No subtasks yet.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(theme.secondaryLabelColor)
                    .italic()
            } else {
                ForEach(liveTask.subtasks) { sub in
                    HStack(spacing: 12) {
                        Button {
                            viewModel.toggleSubTask(taskID: liveTask.id ?? "", subID: sub.id)
                        } label: {
                            Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(sub.isCompleted ? theme.accentColor : theme.secondaryLabelColor)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)

                        Text(sub.title)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(theme.labelColor)
                            .strikethrough(sub.isCompleted, color: theme.secondaryLabelColor)
                            .opacity(sub.isCompleted ? 0.55 : 1.0)

                        Spacer()

                        Button {
                            if let idx = liveTask.subtasks.firstIndex(where: { $0.id == sub.id }) {
                                viewModel.deleteSubTasks(taskID: liveTask.id ?? "", at: IndexSet(integer: idx))
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(Color.red.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }

            // New subtask input field
            if showSubtaskField {
                HStack {
                    TextField("New subtask…", text: $newSubtaskTitle)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(theme.labelColor)
                        .onSubmit { commitNewSubtask() }

                    Button("Add") { commitNewSubtask() }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.accentColor)
                        .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top, 4)
            }

            // Add / Cancel subtask button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showSubtaskField.toggle()
                    if !showSubtaskField { newSubtaskTitle = "" }
                }
            } label: {
                Label(showSubtaskField ? "Cancel" : "Add Subtask", systemImage: showSubtaskField ? "xmark" : "plus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(showSubtaskField ? theme.secondaryLabelColor : theme.accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    // MARK: - Danger Zone Card

    private var dangerCard: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Task")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.10))
            .foregroundColor(.red)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Helpers

    private func beginEditing() {
        populateDraft()
        isEditing = true
    }

    private func populateDraft() {
        draftTitle           = liveTask.title
        draftDesc            = liveTask.description
        draftPriority        = liveTask.priority
        draftEnableStart     = liveTask.startDate != nil
        draftStartDate       = liveTask.startDate ?? Date()
        draftEnableDeadline  = liveTask.deadline  != nil
        draftDeadline        = liveTask.deadline  ?? Date()
    }

    private func commitEdits() {
        var updated          = liveTask
        updated.title        = draftTitle.trimmingCharacters(in: .whitespaces).isEmpty ? liveTask.title : draftTitle
        updated.description  = draftDesc
        updated.priority     = draftPriority
        updated.startDate    = draftEnableStart     ? draftStartDate : nil
        updated.deadline     = draftEnableDeadline  ? draftDeadline  : nil
        viewModel.updateTask(updated)
        isEditing = false
    }

    private func commitNewSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.addSubTask(to: liveTask.id ?? "", title: trimmed)
        newSubtaskTitle = ""
        showSubtaskField = false
    }
}
