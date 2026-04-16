import SwiftUI

struct TaskRowView: View {
    @Binding var task: Task
    let theme: Theme
    
    // Updated closures to pass back the whole Task object
    let onToggle: (Task) -> Void
    let onDelete: (Task) -> Void

    @State private var isFlashing: Bool = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                
                // ── Completion Circle Button ──────────────────────────────
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isFlashing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onToggle(task) // Passing the task object
                        isFlashing = false
                    }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(task.isCompleted ? theme.accentColor : theme.secondaryLabelColor)
                        .scaleEffect(isFlashing ? 1.30 : 1.0)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)

                // ── Task Text ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.labelColor)
                        .strikethrough(task.isCompleted, color: theme.secondaryLabelColor)
                        .opacity(task.isCompleted ? 0.55 : 1.0)

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(theme.secondaryLabelColor)
                            .lineLimit(2)
                            .opacity(task.isCompleted ? 0.45 : 0.85)
                    }

                    if let dl = task.deadline {
                        deadlineChip(for: dl)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: task.priority.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(task.priority.color)
                    .opacity(task.isCompleted ? 0.35 : 1.0)
            }

            if let progress = task.subtaskProgress {
                subtaskProgressSection(progress: progress)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onToggle(task)
            } label: {
                Label(task.isCompleted ? "Undo" : "Done",
                      systemImage: task.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
            }
            .tint(theme.accentColor)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete(task)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: task.isCompleted)
    }

    @ViewBuilder
    private func deadlineChip(for date: Date) -> some View {
        let chipColor = task.isOverdue ? Color.red : (task.isDueSoon ? Color.orange : theme.secondaryLabelColor)
        let icon = task.isOverdue ? "exclamationmark.circle.fill" : (task.isDueSoon ? "clock.fill" : "calendar")

        Label(dateFormatter.string(from: date), systemImage: icon)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(chipColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(chipColor.opacity(0.12))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func subtaskProgressSection(progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(theme.secondaryLabelColor.opacity(0.18)).frame(height: 5)
                    RoundedRectangle(cornerRadius: 3).fill(theme.accentColor).frame(width: geo.size.width * CGFloat(progress), height: 5)
                }
            }
            .frame(height: 5)
            Text("\(task.completedSubtaskCount) of \(task.subtasks.count) subtasks")
                .font(.system(size: 11)).foregroundColor(theme.secondaryLabelColor)
        }
    }
}
