//
//  AddTaskView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: Modal sheet for creating a new task. Owns local draft @State for
//           all form fields so that cancellation never pollutes the ViewModel.
//           Only writes to the ViewModel on successful confirmation.
//
//  DATA FLOW:
//    (DOWN) viewModel → @ObservedObject (reads currentTheme, calls addTask)
//    (UP)   on save   → calls viewModel.addTask(…) then dismisses itself
//

import SwiftUI

// -----------------------------------------------------------------------------
// AddTaskView
// Receives the ViewModel as @ObservedObject (observes but does NOT own it;
// ContentView owns it via @StateObject).
// -----------------------------------------------------------------------------
struct AddTaskView: View {
    @ObservedObject var viewModel: ToDoViewModel
    @Environment(\.dismiss) private var dismiss

    // ── Local Draft State ─────────────────────────────────────────────────────
    // These are intentionally NOT stored in the ViewModel. If the user cancels,
    // nothing leaks into the app's persistent state.
    @State private var titleText: String        = ""
    @State private var descriptionText: String  = ""
    @State private var selectedPriority: Priority = .medium
    @State private var isTitleEmpty: Bool       = false   // Validation flag

    // Date pickers
    @State private var enableStartDate: Bool    = false
    @State private var startDate: Date          = Date()
    @State private var enableDeadline: Bool     = false
    @State private var deadline: Date           = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

    // Convenience alias
    private var theme: Theme { viewModel.currentTheme }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matches the current app theme
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // ── Title Field ───────────────────────────────────
                        formSection(label: "TASK TITLE", icon: "pencil.line") {
                            TextField("What needs to be done?", text: $titleText)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(theme.labelColor)
                                .padding(14)
                                .background(theme.cardSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            isTitleEmpty ? Color.red.opacity(0.7) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )

                            // Inline validation message (animated)
                            if isTitleEmpty {
                                Text("Title cannot be empty.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .transition(.opacity)
                            }
                        }

                        // ── Description Field ─────────────────────────────
                        formSection(label: "NOTES (OPTIONAL)", icon: "text.alignleft") {
                            TextField("Add more details…", text: $descriptionText, axis: .vertical)
                                .lineLimit(4, reservesSpace: true)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(theme.labelColor)
                                .padding(14)
                                .background(theme.cardSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // ── Priority Picker ───────────────────────────────
                        formSection(label: "PRIORITY", icon: "flag.fill") {
                            HStack(spacing: 10) {
                                ForEach(Priority.allCases) { priority in
                                    PriorityChip(
                                        priority: priority,
                                        isSelected: selectedPriority == priority
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPriority = priority
                                        }
                                    }
                                }
                            }
                        }

                        // ── Start Date ────────────────────────────────────
                        formSection(label: "START DATE", icon: "play.circle.fill") {
                            datePickerRow(
                                isEnabled: $enableStartDate,
                                date: $startDate,
                                label: "Start date",
                                minDate: nil
                            )
                        }

                        // ── Deadline ──────────────────────────────────────
                        formSection(label: "DEADLINE", icon: "calendar.badge.exclamationmark") {
                            datePickerRow(
                                isEnabled: $enableDeadline,
                                date: $deadline,
                                label: "Deadline",
                                minDate: enableStartDate ? startDate : Date()
                            )
                        }

                        Spacer(minLength: 20)

                        // ── Save Button ───────────────────────────────────
                        Button { saveTask() } label: {
                            Label("Add Task", systemImage: "plus.circle.fill")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.accentColor.opacity(0.75)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: theme.accentColor.opacity(0.45), radius: 12, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }

    // MARK: - Private Helpers
    
    // iOS 16 / Xcode 14 compatible uneven corner radius shape
    private struct RoundedCorners: Shape {
        var tl: CGFloat = 0
        var tr: CGFloat = 0
        var bl: CGFloat = 0
        var br: CGFloat = 0

        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
                p.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
                p.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
                p.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
                p.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
                p.closeSubpath()
            }
        }
    }

    /// Reusable section layout: labelled header + arbitrary content below.
    @ViewBuilder
    private func formSection<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)
            content()
        }
    }

    /// A toggle + DatePicker row used for both Start Date and Deadline.
    @ViewBuilder
    private func datePickerRow(
        isEnabled: Binding<Bool>,
        date: Binding<Date>,
        label: String,
        minDate: Date?
    ) -> some View {
        VStack(spacing: 0) {
            // Enable / disable toggle row
            HStack {
                Toggle(isOn: isEnabled) {
                    Text(isEnabled.wrappedValue ? label : "Not set")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(isEnabled.wrappedValue ? theme.labelColor : theme.secondaryLabelColor)
                }
                .tint(theme.accentColor)
            }
            .padding(14)
            .background(theme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: isEnabled.wrappedValue ? 0 : 14, style: .continuous))
            .clipShape(RoundedCorners(
                tl: 14,
                tr: 14,
                bl: isEnabled.wrappedValue ? 0 : 14,
                br: isEnabled.wrappedValue ? 0 : 14
            ))

            // DatePicker revealed when enabled
            if isEnabled.wrappedValue {
                Divider()
                    .background(theme.secondaryLabelColor.opacity(0.2))
                DatePicker(
                    "",
                    selection: date,
                    in: minDate.map { $0... } ?? (.distantPast...),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(theme.accentColor)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .background(theme.cardSurface)
                .clipShape(RoundedCorners(tl: 0, tr: 0, bl: 14, br: 14))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isEnabled.wrappedValue)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    /// Validates the draft and — if valid — submits it to the ViewModel.
    private func saveTask() {
        guard !titleText.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { isTitleEmpty = true }
            return
        }
        viewModel.addTask(
            title: titleText,
            description: descriptionText,
            priority: selectedPriority,
            startDate: enableStartDate ? startDate : nil,
            deadline: enableDeadline ? deadline : nil
        )
        dismiss()
    }
}

// MARK: - Preview
struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView(viewModel: ToDoViewModel())
    }
}
