//
//  ProfileView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: Displays and allows editing of the user's profile (name, bio,
//           avatar emoji) and shows live task statistics derived from the
//           ViewModel. Part of the TabView navigation.
//

import SwiftUI

// Emoji options the user can pick as their avatar
private let avatarEmojis = [
    "🧑‍💻", "👩‍💻", "🧑‍🎨", "👩‍🎨", "🧑‍🚀", "👩‍🚀",
    "🦊", "🐼", "🦁", "🐸", "🐧", "🦋",
    "🌟", "⚡️", "🔥", "🎯", "🚀", "🎸"
]

// -----------------------------------------------------------------------------
// ProfileView
// Receives the ViewModel as @ObservedObject — it OBSERVES but does NOT own it.
// ContentView owns it via @StateObject.
// -----------------------------------------------------------------------------
struct ProfileView: View {
    @ObservedObject var viewModel: ToDoViewModel
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var isEditingProfile: Bool     = false
    @State private var draftName: String          = ""
    @State private var draftBio: String           = ""
    @State private var showEmojiPicker: Bool      = false

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
                    VStack(spacing: 24) {

                        // ── Avatar & Name ─────────────────────────────────
                        avatarSection

                        // ── Stats Grid ────────────────────────────────────
                        statsGrid

                        // ── Activity Bar ──────────────────────────────────
                        if viewModel.totalTaskCount > 0 {
                            activitySection
                        }

                        // Extra space so the last card clears the floating tab bar
                        Color.clear.frame(height: 110)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(theme.preferredColorScheme)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditingProfile {
                        Button("Done") { commitProfile() }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentColor)
                    } else {
                        Button("Edit") { beginEditing() }
                            .foregroundColor(theme.accentColor)
                    }
                }
            }
            // Emoji picker sheet
            .sheet(isPresented: $showEmojiPicker) {
                emojiPickerSheet
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 16) {
            // Avatar circle
            Button {
                if isEditingProfile { showEmojiPicker = true }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor.opacity(0.3),
                                         theme.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: theme.accentColor.opacity(0.35),
                                radius: 20, y: 8)

                    Text(viewModel.profile.avatarEmoji)
                        .font(.system(size: 56))

                    if isEditingProfile {
                        // Edit badge
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 36, y: 36)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditingProfile)

            // Display name / bio (edit mode) or just the email badge (view mode)
            VStack(spacing: 6) {
                if isEditingProfile {
                    TextField("Display name", text: $draftName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.labelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    TextField("Short bio", text: $draftBio)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(theme.secondaryLabelColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                // Account email badge — always visible, never editable
                if let email = authVM.currentEmail {
                    HStack(spacing: 5) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 11, weight: .medium))
                        Text(email)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(theme.accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.accentColor.opacity(0.13))
                            .overlay(
                                Capsule()
                                    .stroke(theme.accentColor.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .padding(.top, isEditingProfile ? 8 : 0)
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            statCell(
                value: viewModel.totalTaskCount,
                label: "Total",
                icon: "checklist",
                color: theme.accentColor
            )
            statCell(
                value: viewModel.activeTaskCount,
                label: "Active",
                icon: "circle.dotted",
                color: Color(hue: 0.58, saturation: 0.60, brightness: 0.90)
            )
            statCell(
                value: viewModel.completedTaskCount,
                label: "Done",
                icon: "checkmark.circle.fill",
                color: Color(hue: 0.38, saturation: 0.70, brightness: 0.75)
            )
            statCell(
                value: viewModel.overdueTaskCount,
                label: "Overdue",
                icon: "exclamationmark.circle.fill",
                color: .red
            )
        }
    }

    @ViewBuilder
    private func statCell(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)

            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.labelColor)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("COMPLETION RATE", systemImage: "chart.bar.fill")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.secondaryLabelColor)

            let pct = viewModel.totalTaskCount > 0
                ? Double(viewModel.completedTaskCount) / Double(viewModel.totalTaskCount)
                : 0.0

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(Int(pct * 100))% complete")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.labelColor)
                    Spacer()
                    Text("\(viewModel.completedTaskCount)/\(viewModel.totalTaskCount) tasks")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(theme.secondaryLabelColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.secondaryLabelColor.opacity(0.15))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.70)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(pct), height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: pct)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(16)
        .background(theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    // MARK: - Emoji Picker Sheet

    private var emojiPickerSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 6),
                    spacing: 16
                ) {
                    ForEach(avatarEmojis, id: \.self) { emoji in
                        Button {
                            viewModel.profile.avatarEmoji = emoji
                            viewModel.saveProfile()
                            showEmojiPicker = false
                        } label: {
                            Text(emoji)
                                .font(.system(size: 38))
                                .padding(8)
                                .background(
                                    viewModel.profile.avatarEmoji == emoji
                                        ? theme.accentColor.opacity(0.2)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEmojiPicker = false }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }

    // MARK: - Edit Helpers

    private func beginEditing() {
        draftName = viewModel.profile.name
        draftBio  = viewModel.profile.bio
        withAnimation { isEditingProfile = true }
    }

    private func commitProfile() {
        viewModel.profile.name = draftName.isEmpty ? viewModel.profile.name : draftName
        viewModel.profile.bio  = draftBio
        viewModel.saveProfile()
        withAnimation { isEditingProfile = false }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ToDoViewModel(uid: "preview"))
    }
}
