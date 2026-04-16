//
//  SettingsView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: App-wide settings: theme selection, data controls, and app info.
//           Part of the TabView navigation. Previously the theme selector lived
//           in a slide-down panel — it now lives permanently here.
//

import SwiftUI

// -----------------------------------------------------------------------------
// SettingsView
// Receives the ViewModel via @ObservedObject; does NOT own it.
// -----------------------------------------------------------------------------
struct SettingsView: View {
    @ObservedObject var viewModel: ToDoViewModel

    @State private var showClearConfirmation: Bool   = false
    @State private var showResetConfirmation: Bool   = false
    @State private var notificationsEnabled: Bool    = true
    @State private var hapticFeedback: Bool          = true
    @State private var showCompletedInList: Bool     = true

    private var theme: Theme { viewModel.currentTheme }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Appearance ────────────────────────────────────
                        settingsSection(title: "APPEARANCE", icon: "paintpalette.fill") {
                            themeSelector
                        }

                        // ── Preferences ───────────────────────────────────
                        settingsSection(title: "PREFERENCES", icon: "slider.horizontal.3") {
                            VStack(spacing: 0) {
                                toggleRow(
                                    label: "Notifications",
                                    subtitle: "Deadline reminders",
                                    icon: "bell.fill",
                                    iconColor: Color(hue: 0.08, saturation: 0.85, brightness: 0.90),
                                    isOn: $notificationsEnabled
                                )
                                Divider().background(theme.secondaryLabelColor.opacity(0.2))
                                toggleRow(
                                    label: "Haptic Feedback",
                                    subtitle: "Vibrate on interactions",
                                    icon: "iphone.radiowaves.left.and.right",
                                    iconColor: Color(hue: 0.58, saturation: 0.60, brightness: 0.90),
                                    isOn: $hapticFeedback
                                )
                                Divider().background(theme.secondaryLabelColor.opacity(0.2))
                                toggleRow(
                                    label: "Show Completed",
                                    subtitle: "Include completed tasks in All",
                                    icon: "checkmark.circle.fill",
                                    iconColor: Color(hue: 0.38, saturation: 0.70, brightness: 0.75),
                                    isOn: $showCompletedInList
                                )
                            }
                        }

                        // ── Data ──────────────────────────────────────────
                        settingsSection(title: "DATA", icon: "internaldrive.fill") {
                            VStack(spacing: 0) {
                                actionRow(
                                    label: "Clear Completed Tasks",
                                    icon: "checkmark.circle.trianglebadge.exclamationmark",
                                    iconColor: Color(hue: 0.11, saturation: 0.85, brightness: 0.95),
                                    destructive: false
                                ) {
                                    showClearConfirmation = true
                                }

                                Divider().background(theme.secondaryLabelColor.opacity(0.2))

                                actionRow(
                                    label: "Reset All Data",
                                    icon: "trash.fill",
                                    iconColor: .red,
                                    destructive: true
                                ) {
                                    showResetConfirmation = true
                                }
                            }
                        }

                        // ── About ─────────────────────────────────────────
                        settingsSection(title: "ABOUT", icon: "info.circle.fill") {
                            VStack(spacing: 0) {
                                infoRow(label: "App Name",  value: "To-Do Pro")
                                Divider().background(theme.secondaryLabelColor.opacity(0.2))
                                infoRow(label: "Version",   value: "2.0.0")
                                Divider().background(theme.secondaryLabelColor.opacity(0.2))
                                infoRow(label: "Developer", value: "Niko Yoga Pranata")
                                Divider().background(theme.secondaryLabelColor.opacity(0.2))
                                infoRow(label: "Built with", value: "SwiftUI • MVVM")
                            }
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            // Clear completed confirmation
            .confirmationDialog(
                "Clear all completed tasks?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Completed", role: .destructive) {
                    withAnimation { viewModel.clearCompletedTasks() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove \(viewModel.completedTaskCount) completed task(s).")
            }
            // Reset confirmation
            .confirmationDialog(
                "Reset all app data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    withAnimation { resetAllData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All tasks and profile data will be permanently deleted.")
            }
        }
    }

    // MARK: - Theme Selector

    private var themeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Theme.allCases) { t in
                    ThemeSwatchButton(
                        theme: t,
                        isSelected: viewModel.currentTheme == t
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.currentTheme = t
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Reusable Row Types

    @ViewBuilder
    private func toggleRow(
        label: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            iconBadge(systemName: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(theme.labelColor)
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(theme.secondaryLabelColor)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .tint(theme.accentColor)
                .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func actionRow(
        label: String,
        icon: String,
        iconColor: Color,
        destructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge(systemName: icon, color: iconColor)
                Text(label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(destructive ? .red : theme.labelColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.secondaryLabelColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(theme.labelColor)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func iconBadge(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
            )
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)
                .padding(.horizontal, 4)

            content()
                .background(theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    // MARK: - Data Actions

    private func resetAllData() {
        // Delete all tasks from Firestore (listener will update tasks array automatically)
        viewModel.deleteAllTasks()
        // Reset profile to defaults and persist locally
        viewModel.profile = UserProfile()
        viewModel.saveProfile()
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: ToDoViewModel())
    }
}
