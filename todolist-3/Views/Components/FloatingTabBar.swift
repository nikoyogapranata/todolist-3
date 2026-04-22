//
//  FloatingTabBar.swift
//  todolist-3
//
//  LAYER: View / Component
//  PURPOSE: A floating pill-shaped tab bar that replaces the native UITabBar.
//           The system tab bar must be hidden via UITabBar.appearance().isHidden = true
//           before this is used (done in ContentView.init).
//           Compatible with iOS 16.4 / Xcode 14.3.1.
//

import SwiftUI

// =============================================================================
// MARK: - Tab Item Model
// =============================================================================

private struct TabItem {
    let tag: Int
    let icon: String
    let selectedIcon: String
    let label: String
}

private let tabItems: [TabItem] = [
    TabItem(tag: 0, icon: "checklist",       selectedIcon: "checklist",            label: "Tasks"),
    TabItem(tag: 1, icon: "person",          selectedIcon: "person.fill",          label: "Profile"),
    TabItem(tag: 2, icon: "gearshape",       selectedIcon: "gearshape.fill",       label: "Settings"),
]

// =============================================================================
// MARK: - FloatingTabBar
// =============================================================================

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let theme: Theme

    // Glassmorphism pill background colours differ per theme darkness
    private var pillBackground: Color {
        switch theme {
        case .light, .cherryBlossom, .autumn:
            return Color.white.opacity(0.75)
        default:
            return Color(white: 0.14).opacity(0.88)
        }
    }

    private var pillBorder: Color {
        switch theme {
        case .light, .cherryBlossom, .autumn:
            return Color.black.opacity(0.07)
        default:
            return Color.white.opacity(0.10)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabItems, id: \.tag) { item in
                PillTabButton(
                    item: item,
                    isSelected: selectedTab == item.tag,
                    accentColor: theme.accentColor,
                    labelColor: theme.labelColor
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = item.tag
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            // Glassmorphism pill
            Capsule()
                .fill(pillBackground)
                .shadow(
                    color: Color.black.opacity(0.18),
                    radius: 24,
                    y: 8
                )
                .overlay(
                    Capsule()
                        .stroke(pillBorder, lineWidth: 1)
                )
        )
        .background(
            // Extra blur layer for the glass effect
            Capsule()
                .fill(pillBackground)
                .blur(radius: 0.5)
        )
    }
}

// =============================================================================
// MARK: - PillTabButton
// =============================================================================

private struct PillTabButton: View {
    let item: TabItem
    let isSelected: Bool
    let accentColor: Color
    let labelColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accentColor : labelColor.opacity(0.45))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)

                Text(item.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? accentColor : labelColor.opacity(0.40))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(accentColor.opacity(0.13))
                            .padding(.horizontal, 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}
