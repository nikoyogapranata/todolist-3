//
//  LoginView.swift
//  todolist-3
//
//  LAYER: View
//  PURPOSE: Email + Password login form. Validates inputs locally before
//           calling AuthViewModel.signIn(). Displays inline error messages
//           and a loading state. Compatible with iOS 16.4+.
//

import SwiftUI

// =============================================================================
// MARK: - LoginView
// =============================================================================

struct LoginView: View {

    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    // ── Form State ────────────────────────────────────────────────────────────

    @State private var email: String          = ""
    @State private var password: String       = ""
    @State private var showPassword: Bool     = false

    /// Local validation error shown immediately, before hitting Firebase.
    @State private var localError: String?    = nil

    /// Focus state for sequential keyboard tabbing.
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient — shows through the transparent nav bar
                LinearGradient(
                    colors: [
                        Color(hue: 0.62, saturation: 0.75, brightness: 0.22),
                        Color(hue: 0.72, saturation: 0.60, brightness: 0.15),
                        Color(hue: 0.58, saturation: 0.55, brightness: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        headerBlock
                        formCard
                        signInButton
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.88))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Header

    private var headerBlock: some View {
        VStack(spacing: 8) {
            Text("Welcome back")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Sign in to continue")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 0) {

            // Email field
            AuthTextField(
                label: "Email",
                icon: "envelope.fill",
                text: $email,
                keyboardType: .emailAddress,
                contentType: .emailAddress,
                focusedField: $focusedField,
                field: .email,
                nextField: .password
            )

            Divider()
                .background(Color.white.opacity(0.08))

            // Password field
            AuthSecureField(
                label: "Password",
                icon: "lock.fill",
                text: $password,
                showText: $showPassword,
                focusedField: $focusedField,
                field: .password,
                onSubmit: { attemptSignIn() }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        // Show whichever error is most current
        .overlay(alignment: .bottom) {
            if let msg = localError ?? authVM.errorMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hue: 0.02, saturation: 0.85, brightness: 1.0))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hue: 0.02, saturation: 0.85, brightness: 1.0).opacity(0.15))
                    )
                    .offset(y: 46)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: localError ?? authVM.errorMessage)
    }

    // MARK: - Sign-In Button

    private var signInButton: some View {
        Button {
            attemptSignIn()
        } label: {
            ZStack {
                if authVM.isLoading {
                    ProgressView()
                        .tint(Color(hue: 0.62, saturation: 0.75, brightness: 0.22))
                } else {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hue: 0.62, saturation: 0.75, brightness: 0.20))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .white.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(authVM.isLoading)
        .opacity(authVM.isLoading ? 0.8 : 1.0)
        .padding(.top, 20) // Extra top padding to clear floating error label
    }

    // MARK: - Back Button

    // MARK: - Validation & Action

    /// Runs local validation first; only calls Firebase if inputs look good.
    private func attemptSignIn() {
        localError = nil
        authVM.errorMessage = nil

        guard validate() else { return }

        // Use the fully-qualified _Concurrency.Task to avoid a name collision
        // with the project's own `Task` Codable model. Both resolve to the
        // same Swift Concurrency type — only the qualifier differs.
        _Concurrency.Task {
            await authVM.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        }
    }

    /// Returns `true` if both fields pass local validation rules.
    @discardableResult
    private func validate() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        if trimmedEmail.isEmpty || password.isEmpty {
            localError = "Please fill in all fields."
            return false
        }
        if !isValidEmail(trimmedEmail) {
            localError = "That doesn't look like a valid email address."
            return false
        }
        if password.count < 6 {
            localError = "Password must be at least 6 characters."
            return false
        }
        return true
    }

    /// Minimal RFC-5322-like email format check using a regex.
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

// =============================================================================
// MARK: - Reusable Auth Field Components (file-private)
// =============================================================================

/// A standard text input styled for the auth screens.
private struct AuthTextField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    @FocusState.Binding var focusedField: LoginView.Field?
    let field: LoginView.Field
    var nextField: LoginView.Field? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 22)

            TextField(label, text: $text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(nextField != nil ? .next : .done)
                .onSubmit {
                    if let next = nextField { focusedField = next }
                    else { focusedField = nil }
                }
                .tint(.white)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
    }
}

/// A password field with a show/hide toggle button.
private struct AuthSecureField: View {
    let label: String
    let icon: String
    @Binding var text: String
    @Binding var showText: Bool

    @FocusState.Binding var focusedField: LoginView.Field?
    let field: LoginView.Field
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 22)

            Group {
                if showText {
                    TextField(label, text: $text)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    SecureField(label, text: $text)
                        .textContentType(.password)
                }
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(.white)
            .focused($focusedField, equals: field)
            .submitLabel(.done)
            .onSubmit { onSubmit?() }
            .tint(.white)

            Button {
                showText.toggle()
            } label: {
                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
