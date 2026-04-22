//
//  RootView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: The root routing view. Reads authState from AuthViewModel and
//           switches between the authenticated and unauthenticated experiences.
//           Lives at the top of the view hierarchy, just below WindowGroup.
//

import SwiftUI

// =============================================================================
// MARK: - RootView
// =============================================================================

struct RootView: View {

    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            switch authVM.authState {

            case .loggedOut:
                // No authenticated session → show the landing / auth flow.
                LandingView()
                    .transition(.opacity)

            case .loggedIn(let user):
                // Authenticated → show the main app, scoped to this user's UID.
                // We create ToDoViewModel here (not in ContentView) so it is
                // re-created fresh whenever the logged-in user changes.
                ContentView(uid: user.uid)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authVM.authState)
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AuthViewModel())
    }
}
