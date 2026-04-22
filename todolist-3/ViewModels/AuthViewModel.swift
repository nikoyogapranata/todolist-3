//
//  AuthViewModel.swift
//  todolist-3
//
//  LAYER: ViewModel
//  PURPOSE: Single source of truth for authentication state.
//           Owns the Firebase Auth session and exposes async/await methods
//           for sign-in, sign-up, and sign-out.
//           Views observe `authState` to decide which screen to show.
//

import SwiftUI
import FirebaseAuth

// =============================================================================
// MARK: - AuthState
// =============================================================================

/// Represents the two possible authentication states of the app.
enum AuthState: Equatable {
    /// No user is signed in.
    case loggedOut
    /// A user is authenticated; their Firebase `User` object is attached.
    case loggedIn(user: FirebaseAuth.User)

    // Equatable conformance — compare by UID so SwiftUI diffs correctly.
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loggedOut, .loggedOut):
            return true
        case (.loggedIn(let a), .loggedIn(let b)):
            return a.uid == b.uid
        default:
            return false
        }
    }
}

// =============================================================================
// MARK: - AuthViewModel
// =============================================================================

/// ObservableObject that manages Firebase Authentication.
/// Inject this into the environment at the app root so every view can access it.
@MainActor
final class AuthViewModel: ObservableObject {

    // ── Published State ───────────────────────────────────────────────────────

    /// The current authentication state. Views switch on this to decide routing.
    @Published var authState: AuthState = .loggedOut

    /// Non-nil while an async auth operation is in progress. Used to show
    /// loading spinners and disable buttons to prevent duplicate submissions.
    @Published var isLoading: Bool = false

    /// The last auth error to display inline. Cleared before each new request.
    @Published var errorMessage: String? = nil

    // ── Private ───────────────────────────────────────────────────────────────

    /// Firebase Auth state listener handle — retained so we can remove it on deinit.
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // ── Initialisation ────────────────────────────────────────────────────────

    // ── Initialisation ────────────────────────────────────────────────────────

        init() {
            // We call the full path to the Firebase Auth object explicitly
            let firebaseAuth = FirebaseAuth.Auth.auth()
            
            // Attach the listener to the local reference instead of the ambiguous 'Auth' class
            authStateHandle = firebaseAuth.addStateDidChangeListener { [weak self] _, user in
                guard let self = self else { return }
                
                // Hop to the main thread before mutating @Published state.
                // We use DispatchQueue.main.async instead of Swift Concurrency's
                // Task { } to avoid a name collision with the project's own
                // `Task` Codable model, which the compiler would resolve first.
                DispatchQueue.main.async {
                    if let user = user {
                        self.authState = .loggedIn(user: user)
                    } else {
                        self.authState = .loggedOut
                    }
                }
            }
        }

        deinit {
            if let handle = authStateHandle {
                let firebaseAuth = FirebaseAuth.Auth.auth()
                firebaseAuth.removeStateDidChangeListener(handle)
            }
        }

    // =========================================================================
    // MARK: - Computed Helpers
    // =========================================================================

    /// The UID of the currently authenticated user, or nil if signed out.
    /// Use this to build Firestore paths: `users/\(currentUID!)/tasks/`.
    var currentUID: String? {
        guard case .loggedIn(let user) = authState else { return nil }
        return user.uid
    }

    /// The display email of the signed-in user (for UI labels).
    var currentEmail: String? {
        guard case .loggedIn(let user) = authState else { return nil }
        return user.email
    }

    // =========================================================================
    // MARK: - Authentication Methods (async/await)
    // =========================================================================

    /// Signs in an existing user with email and password.
    /// Sets `errorMessage` on failure so the view can display it inline.
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            // authStateHandle callback updates authState automatically.
        } catch let error as NSError {
            errorMessage = friendlyMessage(for: error)
        }
    }

    /// Creates a new Firebase user then signs them in.
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            // authStateHandle callback updates authState automatically.
        } catch let error as NSError {
            errorMessage = friendlyMessage(for: error)
        }
    }

    /// Signs the current user out.
    func signOut() {
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            // authStateHandle will fire and set authState → .loggedOut.
        } catch let error as NSError {
            errorMessage = friendlyMessage(for: error)
        }
    }

    // =========================================================================
    // MARK: - Error Helpers
    // =========================================================================

    /// Maps Firebase `NSError` codes to short, user-friendly strings.
    /// Uses `AuthErrorCode.Code(rawValue:)` which is compatible with
    /// Firebase iOS SDK 8.x–11.x (the range available for Xcode 14.3.1).
    private func friendlyMessage(for error: NSError) -> String {
        switch AuthErrorCode.Code(rawValue: error.code) {
        case .invalidEmail:
            return "That doesn't look like a valid email address."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try logging in."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found for this email. Try signing up."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        default:
            return error.localizedDescription
        }
    }
}
